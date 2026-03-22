defmodule Mix.Tasks.ElixirEvents.Import do
  use Mix.Task

  @shortdoc "Import YAML data files into the database"

  @moduledoc """
  Imports event data from YAML files into the database.

  ## Usage

      mix elixir_events.import
      mix elixir_events.import --data-dir path/to/data

  Defaults to priv/data/ if --data-dir is not specified.
  Safe to run multiple times (idempotent upserts).
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, strict: [data_dir: :string])
    data_dir = opts[:data_dir] || Application.app_dir(:elixir_events, "priv/data")

    case ElixirEvents.Import.run(data_dir) do
      :ok -> Mix.shell().info("Import complete.")
      {:error, errors} -> Mix.raise("Import failed: #{inspect(errors)}")
    end
  end
end
