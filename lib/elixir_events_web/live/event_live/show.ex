defmodule ElixirEventsWeb.EventLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Events, Program, Sponsorship, Talks}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Events.get_event_by_slug(slug,
           preload: [:event_series, :event_links, :event_roles, :cfps]
         ) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Event not found")
         |> redirect(to: ~p"/events")}

      event ->
        talks =
          Talks.list_talks_for_event(event.id)
          |> ElixirEvents.Repo.preload([:event, :recordings, talk_speakers: :profile])

        sponsor_tiers = Sponsorship.list_sponsor_tiers(event.id)

        schedule_days =
          Program.list_schedule_days(event.id)
          |> ElixirEvents.Repo.preload(time_slots: [sessions: :track])

        tracks = Program.list_tracks(event.id)

        {:noreply,
         socket
         |> assign(:page_title, event.name)
         |> assign(:event, event)
         |> assign(:talks, talks)
         |> assign(:sponsor_tiers, sponsor_tiers)
         |> assign(:schedule_days, schedule_days)
         |> assign(:tracks, tracks)}
    end
  end
end
