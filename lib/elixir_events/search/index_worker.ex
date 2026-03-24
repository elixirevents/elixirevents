defmodule ElixirEvents.Search.IndexWorker do
  use Oban.Worker, queue: :search, max_attempts: 3

  alias ElixirEvents.Repo
  require Logger

  @schema_to_ecto %{
    "Event" => {ElixirEvents.Events.Event, []},
    "Talk" => {ElixirEvents.Talks.Talk, [talk_speakers: :profile, event: [], recordings: []]},
    "Profile" => {ElixirEvents.Profiles.Profile, []},
    "Topic" => {ElixirEvents.Topics.Topic, []},
    "EventSeries" => {ElixirEvents.Events.EventSeries, []}
  }

  @impl true
  def perform(%Oban.Job{args: %{"action" => "upsert", "schema" => schema_name, "id" => id}}) do
    with {:ok, doc_module} <- resolve_document_module(schema_name),
         {:ok, record} <- load_record(schema_name, id) do
      document = doc_module.to_search_document(record)
      collection = doc_module.collection_name()

      case ExTypesense.index_document(collection, document, action: "upsert") do
        {:ok, _} ->
          :ok

        {:error, reason} ->
          Logger.error("Typesense upsert failed for #{schema_name}##{id}: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  def perform(%Oban.Job{
        args: %{
          "action" => "delete",
          "collection" => collection,
          "document_id" => doc_id
        }
      }) do
    case ExTypesense.delete_document(collection, doc_id) do
      {:ok, _} ->
        :ok

      {:error, %{"message" => "Could not find" <> _}} ->
        :ok

      {:error, reason} ->
        Logger.error("Typesense delete failed for #{collection}/#{doc_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def perform(%Oban.Job{args: %{"action" => "reindex", "schema" => schema_name}}) do
    with {:ok, doc_module} <- resolve_document_module(schema_name) do
      reindex_collection(doc_module, schema_name)
    end
  end

  defp resolve_document_module(schema_name) do
    module = Module.concat([ElixirEvents.Search.Collections, "#{schema_name}Document"])

    if Code.ensure_loaded?(module) do
      {:ok, module}
    else
      {:error, "Unknown schema: #{schema_name}"}
    end
  end

  defp load_record(schema_name, id) do
    case Map.fetch(@schema_to_ecto, schema_name) do
      {:ok, {ecto_module, preloads}} ->
        import Ecto.Query

        query = from(r in ecto_module, where: r.id == ^id, preload: ^preloads)

        case Repo.one(query) do
          nil -> {:error, "Record not found: #{inspect(ecto_module)} #{id}"}
          record -> {:ok, record}
        end

      :error ->
        {:error, "Unknown schema: #{schema_name}"}
    end
  end

  defp reindex_collection(doc_module, schema_name) do
    collection_name = doc_module.collection_name()
    schema = doc_module.search_schema()

    # Drop existing — ignore errors (collection may not exist yet)
    ExTypesense.drop_collection(collection_name)

    with {:ok, _} <- ExTypesense.create_collection(schema) do
      do_reindex(doc_module, schema_name, collection_name)
    else
      {:error, reason} ->
        Logger.error("Failed to create collection #{collection_name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp do_reindex(doc_module, schema_name, collection_name) do
    case Map.fetch(@schema_to_ecto, schema_name) do
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
