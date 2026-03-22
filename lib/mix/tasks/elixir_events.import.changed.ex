defmodule Mix.Tasks.ElixirEvents.Import.Changed do
  use Mix.Task

  @shortdoc "Import only changed YAML data files (git diff based)"

  @moduledoc """
  Detects which YAML files changed (via git diff against the base branch)
  and imports only the affected series/events.

  ## Usage

      mix elixir_events.import.changed
      mix elixir_events.import.changed --base main
      mix elixir_events.import.changed --data-dir path/to/data

  Uses `git diff --name-only` against the base branch to find changed files.
  Falls back to full import if global files (speakers.yml, topics.yml) changed.
  """

  require Logger

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, strict: [base: :string, data_dir: :string])
    base = opts[:base] || "main"
    data_dir = opts[:data_dir] || Application.app_dir(:elixir_events, "priv/data")

    changed_files = git_changed_files(base)

    if Enum.empty?(changed_files) do
      Mix.shell().info("No YAML data files changed.")
      :ok
    else
      Mix.shell().info("Changed files:\n#{Enum.map_join(changed_files, "\n", &"  #{&1}")}")
      import_changed(changed_files, data_dir)
    end
  end

  defp git_changed_files(base) do
    {output, 0} = System.cmd("git", ["diff", "--name-only", base, "--", "priv/data/"])

    output
    |> String.split("\n", trim: true)
    |> Enum.filter(&String.ends_with?(&1, ".yml"))
  rescue
    _ ->
      Mix.shell().error("Could not run git diff. Falling back to full import.")
      [:full_import]
  end

  defp import_changed([:full_import], data_dir) do
    Mix.shell().info("Running full import...")
    ElixirEvents.Import.run(data_dir)
  end

  defp import_changed(files, data_dir) do
    globals_changed = Enum.any?(files, &global_file?/1)

    if globals_changed do
      Mix.shell().info("Global files changed — importing globals first...")
      ElixirEvents.Import.Topics.run(data_dir)
      ElixirEvents.Import.Profiles.run(data_dir)
      ElixirEvents.Import.Organizations.run(data_dir)
      ElixirEvents.Import.Venues.run(data_dir)
    end

    # Find unique series/event directories affected
    affected_series = extract_affected_series(files)
    affected_events = extract_affected_events(files)

    Enum.each(affected_series, fn series_slug ->
      import_series_and_events(series_slug, affected_events, data_dir)
    end)

    Mix.shell().info("Incremental import complete.")
  end

  defp import_series_and_events(series_slug, affected_events, data_dir) do
    series_dir = Path.join(data_dir, series_slug)

    if File.exists?(Path.join(series_dir, "series.yml")) do
      case ElixirEvents.Import.Series.run(series_dir) do
        {:ok, %{name: name} = series} ->
          Logger.info("Re-imported series: #{name}")
          import_affected_events(series_slug, series, affected_events, series_dir)

        {:error, reason} ->
          Logger.warning("Failed to import series #{series_slug}: #{inspect(reason)}")
      end
    end
  end

  defp import_affected_events(series_slug, series, affected_events, series_dir) do
    affected_events
    |> Enum.filter(fn {s, _e} -> s == series_slug end)
    |> Enum.map(fn {_s, event_slug} -> event_slug end)
    |> Enum.each(fn event_slug ->
      event_dir = Path.join(series_dir, event_slug)

      if File.exists?(Path.join(event_dir, "event.yml")) do
        import_single_event(event_dir, series)
      end
    end)
  end

  defp import_single_event(event_dir, series) do
    case ElixirEvents.Import.Events.run(event_dir, series) do
      {:ok, event} ->
        Logger.info("Re-imported event: #{event.name}")
        ElixirEvents.Import.Talks.run(event_dir, event)
        ElixirEvents.Import.Schedule.run(event_dir, event)
        ElixirEvents.Import.Sponsors.run(event_dir, event)
        ElixirEvents.Import.CFPs.run(event_dir, event)
        ElixirEvents.Import.Roles.run(event_dir, event)

      {:error, reason} ->
        Logger.warning("Failed to import event from #{event_dir}: #{inspect(reason)}")
    end
  end

  defp global_file?(path) do
    basename = Path.basename(path)
    basename in ~w(speakers.yml topics.yml organizations.yml venues.yml)
  end

  defp extract_affected_series(files) do
    files
    |> Enum.reject(&global_file?/1)
    |> Enum.map(fn path ->
      # priv/data/{series_slug}/... -> series_slug
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
    |> Enum.reject(&global_file?/1)
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
