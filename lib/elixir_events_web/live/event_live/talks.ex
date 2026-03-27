defmodule ElixirEventsWeb.EventLive.Talks do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Events, Talks}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    event = Events.get_event_by_slug(slug, preload: [:event_series])

    case event do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Event not found")
         |> push_navigate(to: ~p"/events")}

      event ->
        talks =
          Talks.list_talks_for_event(event.id)
          |> ElixirEvents.Repo.preload([:event, :recordings, talk_speakers: :profile])

        kinds =
          talks
          |> Enum.map(& &1.kind)
          |> Enum.uniq()
          |> Enum.sort_by(fn
            :keynote -> 0
            :talk -> 1
            :workshop -> 2
            :lightning_talk -> 3
            :panel -> 4
          end)

        {:noreply,
         assign(socket,
           page_title: "Talks — #{event.name}",
           page_description: "All talks at #{event.name}.",
           page_url: ElixirEventsWeb.SEO.base_url() <> "/events/#{event.slug}/talks",
           event: event,
           talks: talks,
           filtered_talks: talks,
           kinds: kinds,
           selected_kind: nil
         )}
    end
  end

  @impl true
  def handle_event("filter-kind", %{"kind" => kind}, socket) do
    kind_atom = if kind == "all", do: nil, else: String.to_existing_atom(kind)

    filtered =
      if kind_atom,
        do: Enum.filter(socket.assigns.talks, &(&1.kind == kind_atom)),
        else: socket.assigns.talks

    {:noreply, assign(socket, selected_kind: kind_atom, filtered_talks: filtered)}
  end
end
