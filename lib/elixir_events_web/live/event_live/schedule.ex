defmodule ElixirEventsWeb.EventLive.Schedule do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Events, Program}

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
        schedule_days =
          Program.list_schedule_days(event.id)
          |> ElixirEvents.Repo.preload(time_slots: [sessions: :track])

        tracks = Program.list_tracks(event.id)

        selected_day =
          case schedule_days do
            [first | _] -> first
            [] -> nil
          end

        {:noreply,
         assign(socket,
           page_title: "Schedule — #{event.name}",
           event: event,
           schedule_days: schedule_days,
           tracks: tracks,
           selected_day: selected_day
         )}
    end
  end

  @impl true
  def handle_event("select-day", %{"day-id" => day_id}, socket) do
    day_id = String.to_integer(day_id)
    day = Enum.find(socket.assigns.schedule_days, &(&1.id == day_id))
    {:noreply, assign(socket, :selected_day, day)}
  end
end
