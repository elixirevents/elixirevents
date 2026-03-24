defmodule ElixirEvents.Search.Indexable do
  @moduledoc """
  Behaviour defining how an Ecto schema maps to a Typesense collection.
  """

  @callback collection_name() :: String.t()
  @callback to_search_document(struct()) :: map()
  @callback search_schema() :: map()

  def all_modules do
    [
      ElixirEvents.Search.Collections.EventDocument,
      ElixirEvents.Search.Collections.TalkDocument,
      ElixirEvents.Search.Collections.ProfileDocument,
      ElixirEvents.Search.Collections.TopicDocument,
      ElixirEvents.Search.Collections.EventSeriesDocument
    ]
  end

  def document_module_for(ElixirEvents.Events.Event),
    do: {:ok, ElixirEvents.Search.Collections.EventDocument}

  def document_module_for(ElixirEvents.Talks.Talk),
    do: {:ok, ElixirEvents.Search.Collections.TalkDocument}

  def document_module_for(ElixirEvents.Profiles.Profile),
    do: {:ok, ElixirEvents.Search.Collections.ProfileDocument}

  def document_module_for(ElixirEvents.Topics.Topic),
    do: {:ok, ElixirEvents.Search.Collections.TopicDocument}

  def document_module_for(ElixirEvents.Events.EventSeries),
    do: {:ok, ElixirEvents.Search.Collections.EventSeriesDocument}

  def document_module_for(_), do: :not_indexable
end
