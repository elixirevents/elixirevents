defmodule ElixirEventsWeb.EventLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Events, Program, Sponsorship, Talks}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    event =
      Events.get_event_by_slug(slug,
        preload: [:event_series, :event_links, :event_roles, :cfps, :venue]
      )

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

        sponsor_tiers = Sponsorship.list_sponsor_tiers(event.id)

        schedule_days =
          Program.list_schedule_days(event.id)
          |> ElixirEvents.Repo.preload(time_slots: [sessions: :track])

        tracks = Program.list_tracks(event.id)
        speakers = Talks.list_speakers_for_event(event.id)

        keynote_talks = Enum.filter(talks, &(&1.kind == :keynote))

        # Flatten keynote speakers in talk order (co-speakers stay adjacent)
        keynote_speakers =
          keynote_talks
          |> Enum.flat_map(fn talk ->
            talk.talk_speakers
            |> Enum.sort_by(& &1.position)
            |> Enum.map(& &1.profile)
          end)
          |> Enum.uniq_by(& &1.id)

        # Meetups and workshops get a simpler layout — no section nav, all talks inline
        compact? = event.kind in [:meetup, :workshop]

        sections = build_sections(event, talks, schedule_days, sponsor_tiers, speakers, compact?)

        selected_day =
          case schedule_days do
            [first | _] -> first
            [] -> nil
          end

        {:noreply,
         assign(socket,
           page_title: event.name,
           event: event,
           talks: talks,
           sponsor_tiers: sponsor_tiers,
           schedule_days: schedule_days,
           tracks: tracks,
           speakers: speakers,
           keynote_talks: keynote_talks,
           keynote_speakers: keynote_speakers,
           compact: compact?,
           sections: sections,
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

  # Compact events (meetups, workshops) get no section nav
  defp build_sections(
         _event,
         _talks,
         _schedule_days,
         _sponsor_tiers,
         _speakers,
         true = _compact?
       ),
       do: []

  defp build_sections(event, talks, schedule_days, sponsor_tiers, speakers, _compact?) do
    []
    |> maybe_add(event.description, %{id: "about", label: "About"})
    |> maybe_add(speakers != [], %{id: "speakers", label: "Speakers", count: length(speakers)})
    |> maybe_add(talks != [], %{id: "talks", label: "Talks", count: length(talks)})
    |> maybe_add(schedule_days != [], %{id: "schedule", label: "Schedule"})
    |> maybe_add(event.venue, %{id: "venue", label: "Venue"})
    |> maybe_add(sponsor_tiers != [], %{id: "sponsors", label: "Sponsors"})
  end

  defp maybe_add(sections, condition, section) do
    if condition, do: sections ++ [section], else: sections
  end
end
