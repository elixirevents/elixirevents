defmodule ElixirEvents.Import.Sync do
  @moduledoc """
  Incremental sync of YAML data to the database.

  Reads a manifest of changed file paths (generated at build time via git diff),
  then syncs only the affected records. For global files (speakers, topics, etc.),
  batch-loads existing records and compares field-by-field to avoid unnecessary writes.
  Claimed profiles (user_id set) are always skipped.

  For series/event files, delegates to the existing import modules since the scope
  is already narrow (one series or event per file).
  """

  require Logger

  import Ecto.Query

  alias ElixirEvents.Import
  alias ElixirEvents.Import.Profiles, as: ProfileImport
  alias ElixirEvents.{Organizations, Profiles, Repo, Topics, Venues}

  @manifest_filename ".changed_files"
  @profile_compare_fields ~w(name handle headline bio website avatar_url is_speaker social_links)a

  @global_files %{
    "speakers.yml" => :profiles,
    "topics.yml" => :topics,
    "organizations.yml" => :organizations,
    "venues.yml" => :venues
  }

  # -- Public API --

  @doc """
  Runs the sync using the manifest file in the given data directory.
  Returns :noop if no manifest or no changes, :ok on success.
  """
  def run(data_dir) do
    manifest_path = Path.join(data_dir, @manifest_filename)

    case read_manifest(manifest_path) do
      [] ->
        Logger.info("No data changes to sync.")
        :noop

      changed_files ->
        Logger.info("Syncing #{length(changed_files)} changed file(s)...")
        sync_changed(changed_files, data_dir)
        Logger.info("Data sync complete.")
        :ok
    end
  end

  # -- Manifest --

  defp read_manifest(path) do
    case File.read(path) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.filter(&String.ends_with?(&1, ".yml"))

      {:error, _} ->
        []
    end
  end

  # -- Dispatch --

  defp sync_changed(files, data_dir) do
    sync_globals(files, data_dir)
    sync_series_and_events(files, data_dir)
  end

  defp sync_globals(files, data_dir) do
    Enum.each(@global_files, fn {filename, type} ->
      if file_changed?(files, filename) do
        Logger.info("Syncing #{filename}...")
        sync_global_type(type, data_dir)
      end
    end)
  end

  defp file_changed?(files, filename) do
    Enum.any?(files, &(Path.basename(&1) == filename))
  end

  # -- Global sync (batch-load + compare) --

  defp sync_global_type(:profiles, data_dir) do
    path = Path.join(data_dir, "speakers.yml")

    if File.exists?(path) do
      yaml_entries =
        path
        |> YamlElixir.read_from_file!()
        |> Enum.map(&parse_profile_attrs/1)

      handles = Enum.map(yaml_entries, & &1.handle) |> Enum.reject(&is_nil/1)
      existing = load_profiles_by_handles(handles)

      {new, updated, skipped_claimed, skipped_unchanged} =
        Enum.reduce(yaml_entries, {0, 0, 0, 0}, fn attrs, acc ->
          sync_profile_entry(attrs, acc, existing)
        end)

      Logger.info(
        "Profiles: #{new} new, #{updated} updated, #{skipped_claimed} claimed (skipped), #{skipped_unchanged} unchanged"
      )
    end
  end

  defp sync_global_type(:topics, data_dir) do
    sync_global_file(
      Path.join(data_dir, "topics.yml"),
      &parse_topic_attrs/1,
      &Topics.upsert_topic/1,
      fn entries -> load_by_slug(ElixirEvents.Topics.Topic, Enum.map(entries, & &1.slug)) end,
      ~w(name slug description)a,
      "Topics"
    )
  end

  defp sync_global_type(:organizations, data_dir) do
    sync_global_file(
      Path.join(data_dir, "organizations.yml"),
      &parse_organization_attrs/1,
      &Organizations.upsert_organization/1,
      fn entries ->
        load_by_slug(ElixirEvents.Organizations.Organization, Enum.map(entries, & &1.slug))
      end,
      ~w(name slug description website logo_url)a,
      "Organizations"
    )
  end

  defp sync_global_type(:venues, data_dir) do
    sync_global_file(
      Path.join(data_dir, "venues.yml"),
      &parse_venue_attrs/1,
      &Venues.upsert_venue/1,
      fn entries -> load_by_slug(ElixirEvents.Venues.Venue, Enum.map(entries, & &1.slug)) end,
      ~w(name slug street city region country country_code postal_code latitude longitude website)a,
      "Venues"
    )
  end

  defp sync_profile_entry(attrs, {n, u, sc, su}, existing) do
    case Map.get(existing, attrs.handle) do
      nil ->
        Profiles.upsert_profile(attrs)
        {n + 1, u, sc, su}

      %{user_id: uid} when not is_nil(uid) ->
        Logger.debug("Skipping claimed profile: #{attrs.handle}")
        {n, u, sc + 1, su}

      record ->
        if record_changed?(record, attrs, @profile_compare_fields) do
          Profiles.upsert_profile(attrs)
          {n, u + 1, sc, su}
        else
          {n, u, sc, su + 1}
        end
    end
  end

  defp sync_global_file(path, parse_fn, upsert_fn, load_fn, compare_fields, label) do
    if File.exists?(path) do
      yaml_entries =
        path
        |> YamlElixir.read_from_file!()
        |> Enum.map(parse_fn)

      existing = load_fn.(yaml_entries)

      {new, updated, unchanged} =
        Enum.reduce(yaml_entries, {0, 0, 0}, fn attrs, acc ->
          sync_global_entry(attrs, acc, existing, upsert_fn, compare_fields)
        end)

      Logger.info("#{label}: #{new} new, #{updated} updated, #{unchanged} unchanged")
    end
  end

  defp sync_global_entry(attrs, {n, u, uc}, existing, upsert_fn, compare_fields) do
    case Map.get(existing, attrs.slug) do
      nil ->
        upsert_fn.(attrs)
        {n + 1, u, uc}

      record ->
        if record_changed?(record, attrs, compare_fields) do
          upsert_fn.(attrs)
          {n, u + 1, uc}
        else
          {n, u, uc + 1}
        end
    end
  end

  # -- Series/Event sync (delegate to existing import modules) --

  defp sync_series_and_events(files, data_dir) do
    non_global_files = Enum.reject(files, &global_file?/1)

    if non_global_files != [] do
      affected_series = extract_affected_series(non_global_files)
      affected_events = extract_affected_events(non_global_files)

      Enum.each(affected_series, fn series_slug ->
        sync_series(series_slug, data_dir, affected_events)
      end)
    end
  end

  defp sync_series(series_slug, data_dir, affected_events) do
    series_dir = Path.join(data_dir, series_slug)

    if File.exists?(Path.join(series_dir, "series.yml")) do
      case Import.Series.run(series_dir) do
        {:ok, series} ->
          Logger.info("Synced series: #{series.name}")

          affected_event_slugs =
            affected_events
            |> Enum.filter(fn {s, _e} -> s == series_slug end)
            |> Enum.map(fn {_s, event_slug} -> event_slug end)

          sync_affected_events(affected_event_slugs, series, series_dir)

        {:error, reason} ->
          Logger.warning("Failed to sync series #{series_slug}: #{inspect(reason)}")
      end
    else
      Logger.info("Series #{series_slug} removed from YAML — skipping (clean up manually).")
    end
  end

  defp sync_affected_events(event_slugs, series, series_dir) do
    Enum.each(event_slugs, fn event_slug ->
      event_dir = Path.join(series_dir, event_slug)

      if File.exists?(Path.join(event_dir, "event.yml")) do
        import_single_event(event_dir, series)
      else
        delete_removed_event(event_slug, series.id)
      end
    end)
  end

  defp import_single_event(event_dir, series) do
    case Import.Events.run(event_dir, series) do
      {:ok, event} ->
        Logger.info("Synced event: #{event.name}")
        Import.Talks.run(event_dir, event)
        Import.Workshops.run(event_dir, event)
        Import.Schedule.run(event_dir, event)
        Import.Sponsors.run(event_dir, event)
        Import.CFPs.run(event_dir, event)
        Import.Roles.run(event_dir, event)

      {:error, reason} ->
        Logger.warning("Failed to sync event from #{event_dir}: #{inspect(reason)}")
    end
  end

  defp delete_removed_event(event_slug, series_id) do
    import Ecto.Query

    case Repo.one(
           from(e in ElixirEvents.Events.Event,
             where: e.slug == ^event_slug and e.event_series_id == ^series_id
           )
         ) do
      nil ->
        :ok

      event ->
        Logger.info("Deleting removed event: #{event.name} (#{event_slug})")
        Repo.delete_and_index(event)
    end
  end

  # -- YAML Parsing (mirrors existing import modules) --

  defp parse_profile_attrs(data) do
    %{
      name: data["name"],
      handle: handleize(data["slug"]),
      headline: data["headline"],
      bio: data["bio"],
      website: data["website"],
      avatar_url: data["avatar_url"],
      is_speaker: true,
      social_links: ProfileImport.parse_social_links(data["social_links"])
    }
  end

  defp parse_topic_attrs(data) do
    %{
      name: data["name"],
      slug: data["slug"],
      description: data["description"]
    }
  end

  defp parse_organization_attrs(data) do
    %{
      name: data["name"],
      slug: data["slug"],
      description: data["description"],
      website: data["website"],
      logo_url: data["logo_url"]
    }
  end

  defp parse_venue_attrs(data) do
    %{
      name: data["name"],
      slug: data["slug"],
      street: data["street"],
      city: data["city"],
      region: data["region"],
      country: data["country"],
      country_code: data["country_code"],
      postal_code: data["postal_code"],
      latitude: data["latitude"],
      longitude: data["longitude"],
      website: data["website"]
    }
  end

  # -- DB Batch Loading --

  defp load_profiles_by_handles(handles) do
    ElixirEvents.Profiles.Profile
    |> where([p], p.handle in ^handles)
    |> Repo.all()
    |> Map.new(&{&1.handle, &1})
  end

  defp load_by_slug(schema, slugs) do
    schema
    |> where([r], r.slug in ^slugs)
    |> Repo.all()
    |> Map.new(&{&1.slug, &1})
  end

  # -- Comparison --

  defp record_changed?(record, attrs, fields) do
    Enum.any?(fields, fn field ->
      normalize(Map.get(record, field)) != normalize(Map.get(attrs, field))
    end)
  end

  defp normalize(nil), do: nil
  defp normalize(%Decimal{} = d), do: Decimal.to_float(d)
  defp normalize(val), do: val

  # -- Helpers --

  defp handleize(slug) when is_binary(slug) do
    slug |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "")
  end

  defp handleize(nil), do: nil

  defp global_file?(path) do
    Path.basename(path) in Map.keys(@global_files)
  end

  defp extract_affected_series(files) do
    files
    |> Enum.map(fn path ->
      path
      |> String.replace_prefix("priv/data/", "")
      |> String.split("/")
      |> List.first()
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp extract_affected_events(files) do
    files
    |> Enum.flat_map(fn path ->
      parts =
        path
        |> String.replace_prefix("priv/data/", "")
        |> String.split("/")

      case parts do
        [series, event | _] -> [{series, event}]
        _ -> []
      end
    end)
    |> Enum.uniq()
  end
end
