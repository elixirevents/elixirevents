defmodule ElixirEvents.Search.IndexTrigger do
  @moduledoc """
  Triggers search indexing after successful Repo operations on indexable schemas.

  Called transparently by Repo overrides so no context code needs to change.
  Non-indexable schemas return :ok immediately with a single pattern-match lookup.

  When Oban is running (normal app), enqueues an async job.
  When Oban is not running (release commands), indexes synchronously.
  """

  alias ElixirEvents.Search.{Indexable, Indexer, IndexWorker}

  require Logger

  def after_insert_or_update(%{__struct__: schema_module, id: id}) do
    case Indexable.document_module_for(schema_module) do
      {:ok, _doc_module} ->
        schema_name = schema_module |> Module.split() |> List.last()

        if oban_running?() do
          %{action: "upsert", schema: schema_name, id: id}
          |> IndexWorker.new()
          |> Oban.insert()
          |> log_on_error("upsert", schema_name, id)
        else
          Indexer.upsert(schema_name, id)
        end

      :not_indexable ->
        :ok
    end
  end

  def after_delete(%{__struct__: schema_module, id: id}) do
    case Indexable.document_module_for(schema_module) do
      {:ok, doc_module} ->
        collection = doc_module.collection_name()

        if oban_running?() do
          %{action: "delete", collection: collection, document_id: to_string(id)}
          |> IndexWorker.new()
          |> Oban.insert()
          |> log_on_error("delete", collection, id)
        else
          Indexer.delete(collection, to_string(id))
        end

      :not_indexable ->
        :ok
    end
  end

  defp oban_running? do
    match?(%Oban.Config{}, Oban.Registry.config(Oban))
  rescue
    ArgumentError -> false
  end

  defp log_on_error({:ok, _job}, _action, _target, _id), do: :ok

  defp log_on_error({:error, reason}, action, target, id) do
    Logger.error("Failed to enqueue search #{action} job for #{target}##{id}: #{inspect(reason)}")
    :ok
  end
end
