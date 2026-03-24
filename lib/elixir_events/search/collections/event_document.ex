defmodule ElixirEvents.Search.Collections.EventDocument do
  @moduledoc """
  Maps ElixirEvents.Events.Event to a Typesense document.
  """

  @behaviour ElixirEvents.Search.Indexable

  @impl true
  def collection_name, do: "events"

  @impl true
  def to_search_document(%ElixirEvents.Events.Event{} = event) do
    %{
      id: to_string(event.id),
      name: event.name,
      slug: event.slug,
      description: event.description || "",
      kind: to_string(event.kind),
      status: to_string(event.status),
      format: to_string(event.format),
      start_date: date_to_timestamp(event.start_date),
      end_date: date_to_timestamp(event.end_date),
      location: event.location || "",
      banner: event.banner_url || "",
      color: event.color || ""
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
        %{name: "status", type: "string", facet: true, index: true},
        %{name: "format", type: "string", facet: true, index: true},
        %{name: "start_date", type: "int64", sort: true},
        %{name: "end_date", type: "int64", sort: true, optional: true},
        %{name: "location", type: "string", index: true, optional: true},
        %{name: "banner", type: "string", index: false, optional: true},
        %{name: "color", type: "string", index: false, optional: true}
      ],
      default_sorting_field: "start_date"
    }
  end

  defp date_to_timestamp(nil), do: 0
  defp date_to_timestamp(%Date{} = date), do: Date.to_gregorian_days(date)
end
