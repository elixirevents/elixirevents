defmodule ElixirEvents.Search.Indexer do
  @moduledoc """
  Core Typesense sync logic, usable both from Oban workers and synchronously
  during release commands when Oban isn't running.
  """

  alias ElixirEvents.Repo
  require Logger

  @schema_to_ecto %{
    "Event" => {ElixirEvents.Events.Event, []},
    "Talk" => {ElixirEvents.Talks.Talk, [talk_speakers: :profile, event: [], recordings: []]},
    "Profile" => {ElixirEvents.Profiles.Profile, []},
    "Topic" => {ElixirEvents.Topics.Topic, []},
    "EventSeries" => {ElixirEvents.Events.EventSeries, []}
  }

  def upsert(schema_name, id) do
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

  def delete(collection, doc_id) do
    case ExTypesense.delete_document(collection, doc_id) do
      {:ok, _} ->
        :ok

      {:error, %OpenApiTypesense.ApiResponse{message: "Could not find" <> _}} ->
        :ok

      {:error, reason} ->
        Logger.error("Typesense delete failed for #{collection}/#{doc_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def resolve_document_module(schema_name) do
    module = Module.concat([ElixirEvents.Search.Collections, "#{schema_name}Document"])

    if Code.ensure_loaded?(module) do
      {:ok, module}
    else
      {:error, "Unknown schema: #{schema_name}"}
    end
  end

  def load_record("Profile", id) do
    import Ecto.Query

    query =
      from(p in ElixirEvents.Profiles.Profile,
        left_join: ts in assoc(p, :talk_speakers),
        where: p.id == ^id,
        group_by: p.id,
        select_merge: %{talk_count: count(ts.id)}
      )

    case Repo.one(query) do
      nil -> {:error, "Record not found: Profile #{id}"}
      record -> {:ok, record}
    end
  end

  def load_record("Topic", id) do
    import Ecto.Query

    query =
      from(t in ElixirEvents.Topics.Topic,
        left_join: tt in assoc(t, :talk_topics),
        left_join: te in assoc(t, :event_topics),
        where: t.id == ^id,
        group_by: t.id,
        select_merge: %{talk_count: count(tt.id, :distinct), event_count: count(te.id, :distinct)}
      )

    case Repo.one(query) do
      nil -> {:error, "Record not found: Topic #{id}"}
      record -> {:ok, record}
    end
  end

  def load_record(schema_name, id) do
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

  def schema_to_ecto, do: @schema_to_ecto
end
