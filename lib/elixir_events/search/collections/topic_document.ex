defmodule ElixirEvents.Search.Collections.TopicDocument do
  @moduledoc """
  Maps ElixirEvents.Topics.Topic to a Typesense document.
  Handles virtual talk_count and event_count fields (default to 0 if not loaded).
  """

  @behaviour ElixirEvents.Search.Indexable

  @impl true
  def collection_name, do: "topics"

  @impl true
  def to_search_document(%ElixirEvents.Topics.Topic{} = topic) do
    %{
      id: to_string(topic.id),
      name: topic.name,
      slug: topic.slug,
      description: topic.description || "",
      talk_count: topic.talk_count || 0,
      event_count: topic.event_count || 0
    }
  end

  @impl true
  def search_schema do
    %{
      name: collection_name(),
      fields: [
        %{name: "name", type: "string", index: true},
        %{name: "slug", type: "string", index: false},
        %{name: "description", type: "string", index: true, optional: true},
        %{name: "talk_count", type: "int32", sort: true},
        %{name: "event_count", type: "int32", sort: true}
      ],
      default_sorting_field: "talk_count"
    }
  end
end
