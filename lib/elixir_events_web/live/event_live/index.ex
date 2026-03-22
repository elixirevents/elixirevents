defmodule ElixirEventsWeb.EventLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Events

  @valid_filters ~w(all upcoming past)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter = if params["filter"] in @valid_filters, do: params["filter"], else: "all"

    events =
      case filter do
        "upcoming" -> Events.list_upcoming_events(preload: [:event_series, :cfps])
        "past" -> Events.list_past_events(preload: [:event_series, :cfps])
        _ -> Events.list_events(preload: [:event_series, :cfps])
      end

    {:noreply,
     socket
     |> assign(:page_title, "Events")
     |> assign(:events, events)
     |> assign(:current_filter, filter)
     |> assign(:event_count, length(events))}
  end
end
