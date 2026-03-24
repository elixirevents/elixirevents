defmodule Mix.Tasks.Search.Reindex do
  @moduledoc """
  Reindex all or specific Typesense collections.

  ## Usage

      mix search.reindex          # reindex all collections
      mix search.reindex events   # reindex just events
      mix search.reindex talks profiles  # reindex multiple
  """

  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [] ->
        ElixirEvents.Search.reindex()

      names ->
        Enum.each(names, fn name ->
          case ElixirEvents.Search.reindex(name) do
            :ok -> :ok
            {:error, msg} -> Mix.raise(msg)
          end
        end)
    end

    Mix.shell().info("Reindex jobs enqueued. They will run via Oban.")
  end
end
