defmodule ElixirEventsWeb.EventLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Events
  alias ElixirEvents.Events.Event

  @valid_filters ~w(all upcoming past)
  @valid_kinds Event.kinds() |> Enum.map(&to_string/1)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, show_kind_filter: false)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter = if params["filter"] in @valid_filters, do: params["filter"], else: "all"
    search = params["q"]

    kinds =
      case params["kinds"] do
        nil -> []
        str -> str |> String.split(",") |> Enum.filter(&(&1 in @valid_kinds))
      end

    query_opts = [
      preload: [:event_series, :cfps],
      kinds: if(kinds == [], do: nil, else: kinds),
      search: search
    ]

    events =
      case filter do
        "upcoming" -> Events.list_upcoming_events(query_opts)
        "past" -> Events.list_past_events(query_opts)
        _ -> Events.list_events(query_opts)
      end

    {:noreply,
     socket
     |> assign(:page_title, "Events")
     |> assign(
       :page_description,
       "Browse Elixir & BEAM conferences, meetups, summits, and workshops."
     )
     |> assign(:page_url, ElixirEventsWeb.SEO.base_url() <> "/events")
     |> assign(:jsonld, ElixirEventsWeb.SEO.event_list_jsonld(events))
     |> assign(:events, events)
     |> assign(:current_filter, filter)
     |> assign(:selected_kinds, kinds)
     |> assign(:search, search)
     |> assign(:event_count, length(events))}
  end

  @impl true
  def handle_event("toggle-kind-filter", _params, socket) do
    {:noreply, assign(socket, show_kind_filter: !socket.assigns.show_kind_filter)}
  end

  def handle_event("close-kind-filter", _params, socket) do
    {:noreply, assign(socket, show_kind_filter: false)}
  end

  def handle_event("toggle-kind", %{"kind" => kind}, socket) when kind in @valid_kinds do
    current = socket.assigns.selected_kinds

    new_kinds =
      if kind in current,
        do: List.delete(current, kind),
        else: current ++ [kind]

    params = build_filter_params(socket.assigns.current_filter, new_kinds, socket.assigns.search)
    {:noreply, push_patch(socket, to: ~p"/events?#{params}")}
  end

  def handle_event("clear-kinds", _params, socket) do
    params = build_filter_params(socket.assigns.current_filter, [], socket.assigns.search)
    {:noreply, push_patch(socket, to: ~p"/events?#{params}")}
  end

  @kind_labels %{
    "conference" => "Conferences",
    "meetup" => "Meetups",
    "retreat" => "Retreats",
    "hackathon" => "Hackathons",
    "summit" => "Summits",
    "workshop" => "Workshops",
    "webinar" => "Webinars"
  }

  def kind_options do
    Enum.map(@valid_kinds, fn kind ->
      {kind, Map.get(@kind_labels, kind, kind |> String.capitalize() |> Kernel.<>("s"))}
    end)
  end

  def kind_dot_color("conference"), do: "bg-primary"
  def kind_dot_color("meetup"), do: "bg-secondary"
  def kind_dot_color("retreat"), do: "bg-accent"
  def kind_dot_color("hackathon"), do: "bg-warning"
  def kind_dot_color("summit"), do: "bg-info"
  def kind_dot_color("workshop"), do: "bg-success"
  def kind_dot_color("webinar"), do: "bg-violet-500"
  def kind_dot_color(_), do: "bg-base-content/40"

  def build_filter_params(filter, kinds, search \\ nil) do
    params = if filter == "all", do: %{}, else: %{filter: filter}
    params = if kinds == [], do: params, else: Map.put(params, :kinds, Enum.join(kinds, ","))
    if search in [nil, ""], do: params, else: Map.put(params, :q, search)
  end
end
