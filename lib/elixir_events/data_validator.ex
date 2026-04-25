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

  alias ElixirEvents.Embeds.SocialLink
  alias ElixirEvents.Events.{Event, EventSeries}
  alias ElixirEvents.Slug
  alias ElixirEvents.Sponsorship.Sponsor
  alias ElixirEvents.Submissions.CFP
  alias ElixirEvents.Talks.{Recording, Talk, TalkLink}

  # All enum values derived from Ecto schemas — single source of truth
  @event_kinds Enum.map(Event.kinds(), &to_string/1)
  @event_statuses Enum.map(Event.statuses(), &to_string/1)
  @event_formats Enum.map(Event.formats(), &to_string/1)
  @series_kinds @event_kinds
  @series_frequencies Enum.map(EventSeries.frequencies(), &to_string/1)
  @talk_kinds Enum.map(Talk.kinds(), &to_string/1)
  @talk_levels Enum.map(Talk.levels(), &to_string/1)
  @social_platforms Enum.map(SocialLink.platforms(), &to_string/1)
  @recording_providers Enum.map(Recording.providers(), &to_string/1)
  @talk_link_kinds Enum.map(TalkLink.kinds(), &to_string/1)
  @sponsor_badges Enum.map(Sponsor.badges(), &to_string/1)
  @cfp_kinds Enum.map(CFP.kinds(), &to_string/1)

  # Allowed keys per file type (schema definitions)
  @speaker_keys ~w(name slug headline bio city country_code website social_links)
  @topic_keys ~w(name slug description)
  @organization_keys ~w(name slug website description logo_url)
  @venue_keys ~w(name slug street city region country country_code postal_code latitude longitude website description)
  @series_keys ~w(name slug kind frequency language website color social_links description listed)
  @event_keys ~w(name slug venue_slug kind status format start_date end_date timezone language location website color description tickets_url)
  @talk_keys ~w(title slug kind level language duration abstract speakers topics recordings links)
  @recording_keys ~w(provider external_id url duration thumbnail_url)
  @talk_link_keys ~w(kind url label)
  @social_link_keys ~w(platform url label)
  @sponsor_tier_keys ~w(name level description sponsors)
  @sponsor_keys ~w(slug badge)
  @cfp_keys ~w(name url open_date close_date description kind)
  @workshop_keys ~w(title slug description format experience_level target_audience language start_date end_date venue_slug booking_url attendees_only trainers topics agenda)
  @workshop_agenda_keys ~w(day title start_time end_time items)
  @role_keys ~w(name members)
  @role_member_keys ~w(name position)
  @schedule_keys ~w(tracks days)
  @schedule_track_keys ~w(name color position)
  @schedule_day_keys ~w(name date position time_slots)
  @schedule_time_slot_keys ~w(start_time end_time sessions)
  @schedule_session_keys ~w(talk_slug title track kind)

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
    |> validate_allowed_keys(data, @speaker_keys, "speaker")
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
    |> validate_url(data, "website")
    |> validate_social_links(data)
  end

  defp validate_topic(data) do
    []
    |> validate_allowed_keys(data, @topic_keys, "topic")
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
  end

  defp validate_organization(data) do
    []
    |> validate_allowed_keys(data, @organization_keys, "organization")
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
    |> validate_url(data, "website")
  end

  defp validate_venue(data) do
    []
    |> validate_allowed_keys(data, @venue_keys, "venue")
    |> require_field(data, "name")
    |> require_field(data, "slug")
    |> validate_slug_field(data, "slug")
    |> validate_url(data, "website")
  end

  # --- Series validation ---

  defp validate_series_file(errors, series_dir) do
    path = Path.join(series_dir, "series.yml")

    case parse_yaml(path) do
      {:ok, data} when is_map(data) ->
        errs =
          []
          |> validate_allowed_keys(data, @series_keys, "series")
          |> require_field(data, "name")
          |> require_field(data, "slug")
          |> validate_slug_field(data, "slug")
          |> require_field(data, "kind")
          |> validate_enum(data, "kind", @series_kinds)
          |> validate_enum(data, "frequency", @series_frequencies)
          |> validate_url(data, "website")
          |> validate_social_links(data)
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
      |> validate_workshops_file(event_dir, speaker_slugs, topic_slugs, venue_slugs)
      |> validate_schedule_file(event_dir)
      |> validate_sponsors_file(event_dir, organization_slugs)
      |> validate_cfp_file(event_dir)
      |> validate_roles_file(event_dir)
    end)
  end

  defp validate_event_file(errors, event_dir, venue_slugs) do
    path = Path.join(event_dir, "event.yml")

    case parse_yaml(path) do
      {:ok, data} when is_map(data) ->
        errs =
          []
          |> validate_allowed_keys(data, @event_keys, "event")
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
          |> validate_url(data, "website")
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
      |> validate_allowed_keys(data, @talk_keys, "talk")
      |> require_field(data, "title")
      |> require_field(data, "slug")
      |> validate_slug_field(data, "slug")
      |> require_field(data, "kind")
      |> validate_enum(data, "kind", @talk_kinds)
      |> validate_enum(data, "level", @talk_levels)
      |> validate_integer(data, "duration")
      |> validate_recordings(data)
      |> validate_talk_links(data)

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

  # --- Workshops validation ---

  defp validate_workshops_file(errors, event_dir, speaker_slugs, topic_slugs, venue_slugs) do
    path = Path.join(event_dir, "workshops.yml")

    if File.exists?(path) do
      case parse_yaml(path) do
        {:ok, data} when is_list(data) ->
          workshop_slugs = Enum.map(data, & &1["slug"]) |> Enum.reject(&is_nil/1)
          dupe_errors = find_duplicates(workshop_slugs, path, "workshop slug")

          workshop_errors =
            data
            |> Enum.with_index(1)
            |> Enum.flat_map(fn {workshop, index} ->
              validate_workshop(workshop, speaker_slugs, topic_slugs, venue_slugs)
              |> Enum.map(&prepend_location(&1, path, index))
            end)

          errors ++ dupe_errors ++ workshop_errors

        {:ok, _} ->
          errors ++ [error(path, "expected a YAML list")]

        {:error, reason} ->
          errors ++ [error(path, "YAML parse error: #{reason}")]
      end
    else
      errors
    end
  end

  defp validate_workshop(data, speaker_slugs, topic_slugs, venue_slugs) do
    errs =
      []
      |> validate_allowed_keys(data, @workshop_keys, "workshop")
      |> require_field(data, "title")
      |> require_field(data, "slug")
      |> validate_slug_field(data, "slug")
      |> require_field(data, "start_date")
      |> require_field(data, "end_date")
      |> validate_date(data, "start_date")
      |> validate_date(data, "end_date")
      |> validate_enum(data, "format", @event_formats)
      |> validate_url(data, "booking_url")
      |> validate_reference(data, "venue_slug", venue_slugs, "venues.yml")
      |> validate_workshop_agenda(data)

    # Validate trainer references
    errs =
      case data["trainers"] do
        nil ->
          errs

        trainers when is_list(trainers) ->
          Enum.reduce(trainers, errs, fn trainer_slug, acc ->
            slug = to_string(trainer_slug)

            if MapSet.member?(speaker_slugs, slug) do
              acc
            else
              acc ++ ["trainer '#{slug}' not found in speakers.yml"]
            end
          end)

        _ ->
          errs ++ ["trainers must be a list"]
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

  defp validate_workshop_agenda(errs, data) do
    case data["agenda"] do
      nil ->
        errs

      agenda when is_list(agenda) ->
        Enum.with_index(agenda, 1)
        |> Enum.reduce(errs, fn {day, index}, acc ->
          validate_allowed_keys(acc, day, @workshop_agenda_keys, "workshop agenda day ##{index}")
        end)

      _ ->
        errs ++ ["agenda must be a list"]
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
          errs =
            validate_allowed_keys([], data, @schedule_keys, "schedule")
            |> Enum.map(&prepend_location(&1, path))

          errors ++ errs ++ validate_schedule_structure(data, path, talk_slugs)

        {:ok, _} ->
          errors ++ [error(path, "expected a YAML map")]

        {:error, reason} ->
          errors ++ [error(path, "YAML parse error: #{reason}")]
      end
    else
      errors
    end
  end

  defp validate_schedule_structure(data, path, talk_slugs) do
    track_errors =
      (data["tracks"] || [])
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {track, index} ->
        validate_allowed_keys([], track, @schedule_track_keys, "schedule track")
        |> Enum.map(&prepend_location(&1, path, "track ##{index}"))
      end)

    day_errors =
      (data["days"] || [])
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {day, day_index} ->
        day_key_errors =
          validate_allowed_keys([], day, @schedule_day_keys, "schedule day")
          |> Enum.map(&prepend_location(&1, path, "day ##{day_index}"))

        slot_errors =
          (day["time_slots"] || [])
          |> Enum.with_index(1)
          |> Enum.flat_map(fn {slot, slot_index} ->
            slot_key_errors =
              validate_allowed_keys([], slot, @schedule_time_slot_keys, "schedule time_slot")
              |> Enum.map(&prepend_location(&1, path, "day ##{day_index}, slot ##{slot_index}"))

            session_errors =
              (slot["sessions"] || [])
              |> Enum.with_index(1)
              |> Enum.flat_map(fn {session, sess_index} ->
                loc = "day ##{day_index}, slot ##{slot_index}, session ##{sess_index}"

                key_errors =
                  validate_allowed_keys([], session, @schedule_session_keys, "schedule session")
                  |> Enum.map(&prepend_location(&1, path, loc))

                ref_errors = validate_session_talk_ref(session, path, talk_slugs)
                key_errors ++ ref_errors
              end)

            slot_key_errors ++ session_errors
          end)

        day_key_errors ++ slot_errors
      end)

    track_errors ++ day_errors
  end

  defp validate_session_talk_ref(%{"talk_slug" => slug}, path, talk_slugs) when is_binary(slug) do
    if MapSet.member?(talk_slugs, slug),
      do: [],
      else: [error(path, "session talk_slug '#{slug}' not found in talks.yml")]
  end

  defp validate_session_talk_ref(_session, _path, _talk_slugs), do: []

  # --- CFP validation ---

  defp validate_cfp_file(errors, event_dir) do
    path = Path.join(event_dir, "cfp.yml")

    if File.exists?(path) do
      case parse_yaml(path) do
        {:ok, data} when is_list(data) ->
          cfp_errors =
            data
            |> Enum.with_index(1)
            |> Enum.flat_map(fn {entry, index} ->
              []
              |> validate_allowed_keys(entry, @cfp_keys, "cfp")
              |> require_field(entry, "name")
              |> validate_url(entry, "url")
              |> validate_date(entry, "open_date")
              |> validate_date(entry, "close_date")
              |> validate_enum(entry, "kind", @cfp_kinds)
              |> Enum.map(&prepend_location(&1, path, index))
            end)

          errors ++ cfp_errors

        {:ok, _} ->
          errors ++ [error(path, "expected a YAML list")]

        {:error, reason} ->
          errors ++ [error(path, "YAML parse error: #{reason}")]
      end
    else
      errors
    end
  end

  # --- Roles validation ---

  defp validate_roles_file(errors, event_dir) do
    path = Path.join(event_dir, "roles.yml")

    if File.exists?(path) do
      case parse_yaml(path) do
        {:ok, data} when is_list(data) ->
          role_errors =
            data
            |> Enum.with_index(1)
            |> Enum.flat_map(&validate_role(&1, path))

          errors ++ role_errors

        {:ok, _} ->
          errors ++ [error(path, "expected a YAML list")]

        {:error, reason} ->
          errors ++ [error(path, "YAML parse error: #{reason}")]
      end
    else
      errors
    end
  end

  defp validate_role({entry, index}, path) do
    key_errors =
      []
      |> validate_allowed_keys(entry, @role_keys, "role")
      |> require_field(entry, "name")
      |> Enum.map(&prepend_location(&1, path, index))

    member_errors =
      (entry["members"] || [])
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {member, m_index} ->
        validate_allowed_keys([], member, @role_member_keys, "role member")
        |> require_field(member, "name")
        |> Enum.map(&prepend_location(&1, path, "role ##{index}, member ##{m_index}"))
      end)

    key_errors ++ member_errors
  end

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
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {tier, tier_index} ->
      tier_name = tier["name"]

      tier_key_errors =
        validate_allowed_keys([], tier, @sponsor_tier_keys, "sponsor tier")
        |> Enum.map(&prepend_location(&1, path, "tier ##{tier_index}"))

      sponsor_errors =
        (tier["sponsors"] || [])
        |> Enum.with_index(1)
        |> Enum.flat_map(fn {sponsor, sp_index} ->
          validate_sponsor_ref(sponsor, path, tier_name, organization_slugs)
          |> Enum.map(&prepend_location(&1, path, "tier ##{tier_index}, sponsor ##{sp_index}"))
        end)

      tier_key_errors ++ sponsor_errors
    end)
  end

  defp validate_sponsor_ref(sponsor, _path, tier_name, organization_slugs) when is_map(sponsor) do
    errs = validate_allowed_keys([], sponsor, @sponsor_keys, "sponsor")

    case sponsor["slug"] do
      nil ->
        errs ++ ["sponsor missing 'slug' in tier '#{tier_name}'"]

      slug ->
        errs = validate_enum(errs, sponsor, "badge", @sponsor_badges)

        if MapSet.member?(organization_slugs, slug) do
          errs
        else
          errs ++ ["sponsor '#{slug}' not found in organizations.yml"]
        end
    end
  end

  defp validate_sponsor_ref(_sponsor, _path, tier_name, _organization_slugs) do
    ["sponsor missing 'slug' in tier '#{tier_name}'"]
  end

  # --- Helpers ---

  defp parse_yaml(path) do
    case YamlElixir.read_from_file(path) do
      {:ok, data} -> {:ok, data}
      {:error, %{message: msg}} -> {:error, msg}
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

  defp validate_allowed_keys(errors, data, allowed_keys, context) when is_map(data) do
    data
    |> Map.keys()
    |> Enum.reduce(errors, fn key, acc ->
      if key in allowed_keys do
        acc
      else
        acc ++ ["unknown key '#{key}' in #{context} (allowed: #{Enum.join(allowed_keys, ", ")})"]
      end
    end)
  end

  defp validate_allowed_keys(errors, _data, _allowed_keys, _context), do: errors

  defp validate_url(errors, data, field) do
    case data[field] do
      nil ->
        errors

      url when is_binary(url) ->
        uri = URI.parse(url)

        if uri.scheme in ["http", "https"] and is_binary(uri.host) and uri.host != "" do
          errors
        else
          errors ++ ["invalid URL for '#{field}': '#{url}' (must start with http:// or https://)"]
        end

      _ ->
        errors ++ ["'#{field}' must be a string"]
    end
  end

  defp validate_social_links(errors, data) do
    case data["social_links"] do
      nil ->
        errors

      links when is_list(links) ->
        links
        |> Enum.with_index(1)
        |> Enum.reduce(errors, fn {link, index}, acc ->
          acc
          |> validate_allowed_keys(link, @social_link_keys, "social_link ##{index}")
          |> require_field(link, "platform")
          |> validate_enum(link, "platform", @social_platforms)
          |> require_field(link, "url")
          |> validate_url(link, "url")
        end)

      _ ->
        errors ++ ["social_links must be a list"]
    end
  end

  defp validate_recordings(errors, data) do
    case data["recordings"] do
      nil ->
        errors

      recordings when is_list(recordings) ->
        recordings
        |> Enum.with_index(1)
        |> Enum.reduce(errors, fn {recording, index}, acc ->
          acc
          |> validate_allowed_keys(recording, @recording_keys, "recording ##{index}")
          |> require_field(recording, "provider")
          |> validate_enum(recording, "provider", @recording_providers)
          |> require_field(recording, "url")
          |> validate_url(recording, "url")
        end)

      _ ->
        errors ++ ["recordings must be a list"]
    end
  end

  defp validate_talk_links(errors, data) do
    case data["links"] do
      nil ->
        errors

      links when is_list(links) ->
        links
        |> Enum.with_index(1)
        |> Enum.reduce(errors, fn {link, index}, acc ->
          acc
          |> validate_allowed_keys(link, @talk_link_keys, "link ##{index}")
          |> require_field(link, "kind")
          |> validate_enum(link, "kind", @talk_link_kinds)
          |> require_field(link, "url")
          |> validate_url(link, "url")
        end)

      _ ->
        errors ++ ["links must be a list"]
    end
  end

  defp validate_integer(errors, data, field) do
    case data[field] do
      nil -> errors
      value when is_integer(value) -> errors
      value -> errors ++ ["'#{field}' must be an integer, got: #{inspect(value)}"]
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

  defp prepend_location(message, path, index) when is_binary(message) and is_integer(index) do
    %{path: path, message: message, location: "entry ##{index}"}
  end

  defp prepend_location(message, path, location)
       when is_binary(message) and is_binary(location) do
    %{path: path, message: message, location: location}
  end

  defp prepend_location(message, path, nil) when is_binary(message) do
    %{path: path, message: message, location: nil}
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
