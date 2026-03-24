defmodule ElixirEvents.Search.IndexWorker do
  @moduledoc """
  Oban worker responsible for syncing records with the search backend
  (Typesense): upsert, delete, and full reindex operations per collection.

  Core sync logic lives in `ElixirEvents.Search.Indexer` so it can also be
  called synchronously during release commands when Oban isn't running.
  """
  use Oban.Worker, queue: :search, max_attempts: 3

  alias ElixirEvents.Repo
  alias ElixirEvents.Search.Indexer
  require Logger

  @impl true
  def perform(%Oban.Job{args: %{"action" => "upsert", "schema" => schema_name, "id" => id}}) do
    Indexer.upsert(schema_name, id)
  end

  def perform(%Oban.Job{
        args: %{
          "action" => "delete",
          "collection" => collection,
          "document_id" => doc_id
        }
      }) do
    Indexer.delete(collection, doc_id)
  end

  def perform(%Oban.Job{args: %{"action" => "reindex", "schema" => schema_name}}) do
    with {:ok, doc_module} <- Indexer.resolve_document_module(schema_name) do
      reindex_collection(doc_module, schema_name)
    end
  end

  defp reindex_collection(doc_module, schema_name) do
    collection_name = doc_module.collection_name()
    schema = doc_module.search_schema()

    # Drop existing — ignore errors (collection may not exist yet)
    ExTypesense.drop_collection(collection_name)

    case ExTypesense.create_collection(schema) do
      {:ok, _} ->
        do_reindex(doc_module, schema_name, collection_name)

      {:error, reason} ->
        Logger.error("Failed to create collection #{collection_name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp do_reindex(doc_module, schema_name, collection_name) do
    case Map.fetch(Indexer.schema_to_ecto(), schema_name) do
      {:ok, {ecto_module, preloads}} ->
        import Ecto.Query

        base_query = from(r in ecto_module, order_by: [asc: r.id])
        batch_size = 100

        Stream.resource(
          fn -> 0 end,
          fn offset ->
            records =
              base_query
              |> offset(^offset)
              |> limit(^batch_size)
              |> Repo.all()
              |> Repo.preload(preloads)

            if records == [] do
              {:halt, offset}
            else
              {[records], offset + length(records)}
            end
          end,
          fn _ -> :ok end
        )
        |> Enum.each(fn batch ->
          documents = Enum.map(batch, &doc_module.to_search_document/1)
          ExTypesense.import_documents(collection_name, documents, action: "upsert")
        end)

        Logger.info("Reindexed #{collection_name}")
        :ok

      :error ->
        {:error, "Unknown schema: #{schema_name}"}
    end
  end
end
