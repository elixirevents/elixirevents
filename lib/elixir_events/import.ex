defmodule ElixirEvents.Import do
  @moduledoc false

  require Logger

  alias ElixirEvents.{Events, Import}

  def run(data_dir) do
    Logger.info("Starting import from #{data_dir}")

    errors = []

    # Phase 1: Global entities
    Import.Topics.run(data_dir)
    Import.Profiles.run(data_dir)
    Import.Organizations.run(data_dir)
    Import.Venues.run(data_dir)

    # Phase 2: Series and events
    errors =
      data_dir
      |> list_series_dirs()
      |> Enum.reduce(errors, fn series_dir, acc ->
        case Import.Series.run(series_dir) do
          {:ok, :skipped} ->
            acc

          {:ok, series} ->
            Logger.info("Imported series: #{series.name}")

            event_dirs = list_event_dirs(series_dir)

            yaml_event_slugs =
              Enum.map(event_dirs, fn dir ->
                dir |> Path.join("event.yml") |> YamlElixir.read_from_file!() |> Map.get("slug")
              end)
              |> Enum.reject(&is_nil/1)

            Events.delete_orphaned_events(series.id, yaml_event_slugs)

            Enum.reduce(event_dirs, acc, fn event_dir, inner_acc ->
              import_event(event_dir, series, inner_acc)
            end)

          {:error, reason} ->
            Logger.warning("Failed to import series from #{series_dir}: #{inspect(reason)}")
            [{:series, series_dir, reason} | acc]
        end
      end)

    case errors do
      [] ->
        Logger.info("Import complete")
        :ok

      errors ->
        Logger.warning("Import completed with #{length(errors)} error(s)")
        {:error, Enum.reverse(errors)}
    end
  end

  defp import_event(event_dir, series, errors) do
    case Import.Events.run(event_dir, series) do
      {:ok, event} ->
        Logger.info("Imported event: #{event.name}")
        Import.Talks.run(event_dir, event)
        Import.Workshops.run(event_dir, event)
        Import.Schedule.run(event_dir, event)
        Import.Sponsors.run(event_dir, event)
        Import.CFPs.run(event_dir, event)
        Import.Roles.run(event_dir, event)
        errors

      {:error, reason} ->
        Logger.warning("Failed to import event from #{event_dir}: #{inspect(reason)}")
        [{:event, event_dir, reason} | errors]
    end
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

  @doc false
  def each_with_progress(entries, label, fun) do
    total = length(entries)
    Logger.info("Importing #{total} #{label}...")

    entries
    |> Enum.with_index(1)
    |> Enum.each(fn {entry, index} ->
      fun.(entry)

      if rem(index, 50) == 0 or index == total do
        Logger.info("#{label}: #{index}/#{total} processed")
      end
    end)
  end

  defp list_event_dirs(series_dir) do
    series_dir
    |> File.ls!()
    |> Enum.map(&Path.join(series_dir, &1))
    |> Enum.filter(&(File.dir?(&1) and File.exists?(Path.join(&1, "event.yml"))))
    |> Enum.sort()
  end
end
