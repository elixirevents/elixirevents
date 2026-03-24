defmodule ElixirEvents.Search do
  @moduledoc """
  Search operations for Typesense integration.

  In production (IEx remote console):

      ElixirEvents.Search.reindex()           # reindex all collections
      ElixirEvents.Search.reindex("events")   # reindex just events
      ElixirEvents.Search.reindex("talks")    # reindex just talks
  """

  alias ElixirEvents.Search.{Indexable, IndexWorker}

  require Logger

  @doc """
  Enqueue reindex jobs for all collections or a specific one.
  """
  def reindex do
    Indexable.all_modules()
    |> Enum.each(&enqueue_reindex/1)

    :ok
  end

  def reindex(collection_name) when is_binary(collection_name) do
    module_name = collection_name |> Macro.camelize() |> Kernel.<>("Document")
    doc_module = Module.concat(ElixirEvents.Search.Collections, module_name)

    if Code.ensure_loaded?(doc_module) do
      enqueue_reindex(doc_module)
      :ok
    else
      {:error, "Unknown collection: #{collection_name}"}
    end
  end

  defp enqueue_reindex(doc_module) do
    collection = doc_module.collection_name()
    Logger.info("Enqueuing reindex for #{collection}...")

    schema_name =
      doc_module
      |> Module.split()
      |> List.last()
      |> String.replace_suffix("Document", "")

    %{action: "reindex", schema: schema_name}
    |> IndexWorker.new()
    |> Oban.insert!()
  end
end
