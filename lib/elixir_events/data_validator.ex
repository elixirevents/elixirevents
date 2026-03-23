defmodule ElixirEvents.DataValidator do
  @moduledoc """
  Validates YAML data files in priv/data/ without touching the database.

  Checks:
  - YAML parsability
  - Required fields per file type
  - Enum value validity
  - Slug format
  - Date format
  - Duplicate slugs within scope
  - Speaker/topic references resolve to global files
  - Event venue_slug references resolve to venues.yml
  - Schedule session talk_slug references resolve to talks.yml
  - Sponsor slug references resolve to organizations.yml
  """

  alias ElixirEvents.Slug

  # Enum values must match the Ecto schema definitions
  @event_kinds ~w(conference meetup retreat hackathon summit workshop)
  @event_statuses ~w(announced confirmed cancelled completed)
  @event_formats ~w(in_person online hybrid)
  @series_kinds @event_kinds
  @series_frequencies ~w(yearly monthly quarterly biannual irregular once)
  @talk_kinds ~w(keynote talk workshop panel lightning_talk)
  @talk_levels ~w(beginner intermediate advanced)

  @doc """
  Validates all data files under `data_dir`. Returns `{:ok, stats}` or `{:error, errors}`.
  """
  def validate(data_dir) do
    errors = []

    # Load global references for cross-validation
    speaker_slugs = load_slugs(Path.join(data_dir, "speakers.yml"))
    topic_slugs = load_slugs(Path.join(data_dir, "topics.yml"))
    venue_slugs = load_slugs(Path.join(data_dir, "venues.yml"))
    organization_slugs = load_slugs(Path.join(data_dir, "organizations.yml"))

    errors = errors ++ validate_global_file(data_dir, "speakers.yml", &validate_speaker/1)
    errors = errors ++ validate_global_file(data_dir, "topics.yml", &validate_topic/1)

    errors =
      errors ++ validate_global_file(data_dir, "organizations.yml", &validate_organization/1)

    errors = errors ++ validate_global_file(data_dir, "venues.yml", &validate_venue/1)

    # Validate duplicate slugs in global files
    errors = errors ++ check_duplicate_slugs(data_dir, "speakers.yml")
    errors = errors ++ check_duplicate_slugs(data_dir, "topics.yml")
    errors = errors ++ check_duplicate_slugs(data_dir, "organizations.yml")
    errors = errors ++ check_duplicate_slugs(data_dir, "venues.yml")

    # Validate series and events
    series_dirs = list_series_dirs(data_dir)

    errors =
      Enum.reduce(series_dirs, errors, fn series_dir, acc ->
        acc
        |> validate_series_file(series_dir)
        |> validate_events_in_series(
          series_dir,
          speaker_slugs,
          topic_slugs,
          venue_slugs,
          organization_slugs
        )
      end)

    case errors do
      [] -> {:ok, %{series: length(series_dirs)}}
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  # --- Global file validation ---

  defp validate_global_file(data_dir, filename, validator) do
    path = Path.join(data_dir, filename)

    if File.exists?(path) do
      case parse_yaml(path) do
        {:ok, data} when is_list(data) ->
          data
          |> Enum.with_index(1)
          |> Enum.flat_map(fn {entry, index} ->
            validator.(entry)
            |> Enum.map(&prepend_location(&1, path, index))
          end)

        {:ok, _} ->
          [error(path, "expected a YAML list")]

        {:error, reason} ->
          [error(path, "YAML parse error: #{reason}")]
      end
    else
      []
    end
  end

  defp validate_speaker(data) do
    []
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
  end

  defp validate_topic(data) do
    []
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
  end

  defp validate_organization(data) do
    []
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
  end

  defp validate_venue(data) do
    []
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
  end

  # --- Series validation ---

  defp validate_series_file(errors, series_dir) do
    path = Path.join(series_dir, "series.yml")

    case parse_yaml(path) do
      {:ok, data} when is_map(data) ->
        errs =
          []
          |> require_field(data, "name")
          |> require_field(data, "slug")
          |> validate_slug_field(data, "slug")
          |> require_field(data, "kind")
          |> validate_enum(data, "kind", @series_kinds)
          |> validate_enum(data, "frequency", @series_frequencies)
          |> Enum.map(&prepend_location(&1, path))

        errors ++ errs

      {:ok, _} ->
        errors ++ [error(path, "expected a YAML map")]

      {:error, reason} ->
        errors ++ [error(path, "YAML parse error: #{reason}")]
    end
  end

  # --- Event validation ---

  defp validate_events_in_series(
         errors,
         series_dir,
         speaker_slugs,
         topic_slugs,
         venue_slugs,
         organization_slugs
       ) do
    series_dir
    |> list_event_dirs()
    |> Enum.reduce(errors, fn event_dir, acc ->
      acc
      |> validate_event_file(event_dir, venue_slugs)
      |> validate_talks_file(event_dir, speaker_slugs, topic_slugs)
      |> validate_schedule_file(event_dir)
      |> validate_sponsors_file(event_dir, organization_slugs)
    end)
  end

  defp validate_event_file(errors, event_dir, venue_slugs) do
    path = Path.join(event_dir, "event.yml")

    case parse_yaml(path) do
      {:ok, data} when is_map(data) ->
        errs =
          []
          |> require_field(data, "name")
          |> require_field(data, "slug")
          |> validate_slug_field(data, "slug")
          |> require_field(data, "kind")
          |> validate_enum(data, "kind", @event_kinds)
          |> require_field(data, "status")
          |> validate_enum(data, "status", @event_statuses)
          |> require_field(data, "format")
          |> validate_enum(data, "format", @event_formats)
          |> require_field(data, "start_date")
          |> require_field(data, "end_date")
          |> validate_date(data, "start_date")
          |> validate_date(data, "end_date")
          |> require_field(data, "timezone")
          |> validate_reference(data, "venue_slug", venue_slugs, "venues.yml")
          |> Enum.map(&prepend_location(&1, path))

        errors ++ errs

      {:ok, _} ->
        errors ++ [error(path, "expected a YAML map")]

      {:error, reason} ->
        errors ++ [error(path, "YAML parse error: #{reason}")]
    end
  end

  # --- Talks validation ---

  defp validate_talks_file(errors, event_dir, speaker_slugs, topic_slugs) do
    path = Path.join(event_dir, "talks.yml")

    if File.exists?(path) do
      case parse_yaml(path) do
        {:ok, data} when is_list(data) ->
          talk_slugs = Enum.map(data, & &1["slug"]) |> Enum.reject(&is_nil/1)
          dupe_errors = find_duplicates(talk_slugs, path, "talk slug")

          talk_errors =
            data
            |> Enum.with_index(1)
            |> Enum.flat_map(fn {talk, index} ->
              validate_talk(talk, speaker_slugs, topic_slugs)
              |> Enum.map(&prepend_location(&1, path, index))
            end)

          errors ++ dupe_errors ++ talk_errors

        {:ok, _} ->
          errors ++ [error(path, "expected a YAML list")]

        {:error, reason} ->
          errors ++ [error(path, "YAML parse error: #{reason}")]
      end
    else
      errors
    end
  end

  defp validate_talk(data, speaker_slugs, topic_slugs) do
    errs =
      []
      |> require_field(data, "title")
      |> require_field(data, "slug")
      |> validate_slug_field(data, "slug")
      |> require_field(data, "kind")
      |> validate_enum(data, "kind", @talk_kinds)
      |> validate_enum(data, "level", @talk_levels)

    # Validate speaker references
    errs =
      case data["speakers"] do
        nil ->
          errs

        speakers when is_list(speakers) ->
          Enum.reduce(speakers, errs, fn speaker_slug, acc ->
            slug = to_string(speaker_slug)

            if MapSet.member?(speaker_slugs, slug) do
              acc
            else
              acc ++ ["speaker '#{slug}' not found in speakers.yml"]
            end
          end)

        _ ->
          errs ++ ["speakers must be a list"]
      end

    # Validate topic references
    case data["topics"] do
      nil ->
        errs

      topics when is_list(topics) ->
        Enum.reduce(topics, errs, fn topic_slug, acc ->
          slug = to_string(topic_slug)

          if MapSet.member?(topic_slugs, slug) do
            acc
          else
            acc ++ ["topic '#{slug}' not found in topics.yml"]
          end
        end)

      _ ->
        errs ++ ["topics must be a list"]
    end
  end

  # --- Schedule validation ---

  defp validate_schedule_file(errors, event_dir) do
    path = Path.join(event_dir, "schedule.yml")
    talks_path = Path.join(event_dir, "talks.yml")

    if File.exists?(path) do
      talk_slugs =
        case parse_yaml(talks_path) do
          {:ok, data} when is_list(data) ->
            data |> Enum.map(& &1["slug"]) |> Enum.reject(&is_nil/1) |> MapSet.new()

          _ ->
            MapSet.new()
        end

      case parse_yaml(path) do
        {:ok, data} when is_map(data) ->
          errors ++ validate_schedule_talk_refs(data, path, talk_slugs)

        {:ok, _} ->
          errors ++ [error(path, "expected a YAML map")]

        {:error, reason} ->
          errors ++ [error(path, "YAML parse error: #{reason}")]
      end
    else
      errors
    end
  end

  defp validate_schedule_talk_refs(data, path, talk_slugs) do
    days = data["days"] || []

    days
    |> Enum.flat_map(fn day -> day["time_slots"] || [] end)
    |> Enum.flat_map(fn slot -> slot["sessions"] || [] end)
    |> Enum.flat_map(fn session ->
      validate_session_talk_ref(session, path, talk_slugs)
    end)
  end

  defp validate_session_talk_ref(%{"talk_slug" => slug}, path, talk_slugs) when is_binary(slug) do
    if MapSet.member?(talk_slugs, slug),
      do: [],
      else: [error(path, "session talk_slug '#{slug}' not found in talks.yml")]
  end

  defp validate_session_talk_ref(_session, _path, _talk_slugs), do: []

  # --- Sponsors validation ---

  defp validate_sponsors_file(errors, event_dir, organization_slugs) do
    path = Path.join(event_dir, "sponsors.yml")

    if File.exists?(path) do
      case parse_yaml(path) do
        {:ok, data} when is_list(data) ->
          errors ++ validate_sponsor_refs(data, path, organization_slugs)

        {:ok, _} ->
          errors ++ [error(path, "expected a YAML list")]

        {:error, reason} ->
          errors ++ [error(path, "YAML parse error: #{reason}")]
      end
    else
      errors
    end
  end

  defp validate_sponsor_refs(tiers, path, organization_slugs) do
    tiers
    |> Enum.flat_map(fn tier ->
      tier_name = tier["name"]

      (tier["sponsors"] || [])
      |> Enum.flat_map(&validate_sponsor_ref(&1, path, tier_name, organization_slugs))
    end)
  end

  defp validate_sponsor_ref(%{"slug" => slug}, path, _tier_name, organization_slugs) do
    if MapSet.member?(organization_slugs, slug),
      do: [],
      else: [error(path, "sponsor '#{slug}' not found in organizations.yml")]
  end

  defp validate_sponsor_ref(_sponsor, path, tier_name, _organization_slugs) do
    [error(path, "sponsor missing 'slug' in tier '#{tier_name}'")]
  end

  # --- Helpers ---

  defp parse_yaml(path) do
    case YamlElixir.read_from_file(path) do
      {:ok, data} -> {:ok, data}
      {:error, %{message: msg}} -> {:error, msg}
      {:error, reason} -> {:error, inspect(reason)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp require_field(errors, data, field) do
    case data[field] do
      nil -> errors ++ ["missing required field '#{field}'"]
      "" -> errors ++ ["field '#{field}' cannot be empty"]
      _ -> errors
    end
  end

  defp validate_enum(errors, data, field, valid_values) do
    case data[field] do
      nil ->
        errors

      raw ->
        value = to_string(raw)

        if value in valid_values do
          errors
        else
          errors ++
            ["invalid #{field}: '#{value}' (expected one of: #{Enum.join(valid_values, ", ")})"]
        end
    end
  end

  defp validate_slug_field(errors, data, field) do
    case data[field] do
      nil ->
        errors

      slug when is_binary(slug) ->
        if Slug.valid?(slug) do
          errors
        else
          errors ++
            [
              "invalid slug '#{slug}': only lowercase letters, numbers, and connecting hyphens allowed"
            ]
        end

      other ->
        errors ++ ["slug must be a string, got: #{inspect(other)}"]
    end
  end

  defp validate_reference(errors, data, field, slugs, source_file) do
    case data[field] do
      nil ->
        errors

      slug when is_binary(slug) ->
        if MapSet.member?(slugs, slug) do
          errors
        else
          errors ++ ["#{field} '#{slug}' not found in #{source_file}"]
        end

      _ ->
        errors
    end
  end

  defp validate_date(errors, data, field) do
    case data[field] do
      nil ->
        errors

      %Date{} ->
        errors

      value when is_binary(value) ->
        case Date.from_iso8601(value) do
          {:ok, _} ->
            errors

          {:error, _} ->
            errors ++ ["invalid date for '#{field}': '#{value}' (expected YYYY-MM-DD)"]
        end

      _ ->
        errors
    end
  end

  defp load_slugs(path) do
    case parse_yaml(path) do
      {:ok, data} when is_list(data) ->
        data
        |> Enum.map(& &1["slug"])
        |> Enum.reject(&is_nil/1)
        |> MapSet.new()

      _ ->
        MapSet.new()
    end
  end

  defp check_duplicate_slugs(data_dir, filename) do
    path = Path.join(data_dir, filename)

    case parse_yaml(path) do
      {:ok, data} when is_list(data) ->
        data
        |> Enum.map(& &1["slug"])
        |> Enum.reject(&is_nil/1)
        |> find_duplicates(path, "slug")

      _ ->
        []
    end
  end

  defp find_duplicates(slugs, path, label) do
    slugs
    |> Enum.frequencies()
    |> Enum.filter(fn {_slug, count} -> count > 1 end)
    |> Enum.map(fn {slug, count} ->
      error(path, "duplicate #{label} '#{slug}' (appears #{count} times)")
    end)
  end

  defp error(path, message), do: %{path: path, message: message}

  defp prepend_location(message, path, index \\ nil)

  defp prepend_location(%{} = error, _path, _index), do: error

  defp prepend_location(message, path, index) when is_binary(message) do
    location = if index, do: "entry ##{index}", else: nil
    %{path: path, message: message, location: location}
  end

  defp list_series_dirs(data_dir) do
    case File.ls(data_dir) do
      {:ok, entries} ->
        entries
        |> Enum.map(&Path.join(data_dir, &1))
        |> Enum.filter(&(File.dir?(&1) and File.exists?(Path.join(&1, "series.yml"))))
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end

  defp list_event_dirs(series_dir) do
    case File.ls(series_dir) do
      {:ok, entries} ->
        entries
        |> Enum.map(&Path.join(series_dir, &1))
        |> Enum.filter(&(File.dir?(&1) and File.exists?(Path.join(&1, "event.yml"))))
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end
end
