defmodule ElixirEvents.Search.Collections.EventSeriesDocument do
  @moduledoc """
  Maps ElixirEvents.Events.EventSeries to a Typesense document.
  """

  @behaviour ElixirEvents.Search.Indexable

  @impl true
  def collection_name, do: "event_series"

  @impl true
  def to_search_document(%ElixirEvents.Events.EventSeries{} = series) do
    %{
      id: to_string(series.id),
      name: series.name,
      slug: series.slug,
      description: series.description || "",
      kind: to_string(series.kind),
      frequency: if(series.frequency, do: to_string(series.frequency), else: "")
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
        %{name: "kind", type: "string", facet: true, index: true},
        %{name: "frequency", type: "string", facet: true, index: true, optional: true}
      ]
    }
  end
end
