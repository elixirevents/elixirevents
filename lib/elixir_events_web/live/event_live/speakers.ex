defmodule ElixirEventsWeb.EventLive.Speakers do
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
          |> ElixirEvents.Repo.preload(talk_speakers: :profile)

        speakers = Talks.list_speakers_for_event(event.id)

        keynote_profile_ids =
          talks
          |> Enum.filter(&(&1.kind == :keynote))
          |> Enum.flat_map(& &1.talk_speakers)
          |> Enum.map(& &1.profile_id)
          |> MapSet.new()

        keynote_speakers = Enum.filter(speakers, &MapSet.member?(keynote_profile_ids, &1.id))
        regular_speakers = Enum.reject(speakers, &MapSet.member?(keynote_profile_ids, &1.id))

        talk_counts =
          talks
          |> Enum.flat_map(fn talk ->
            Enum.map(talk.talk_speakers, fn ts -> ts.profile_id end)
          end)
          |> Enum.frequencies()

        {:noreply,
         assign(socket,
           page_title: "Speakers — #{event.name}",
           page_description: "Speakers at #{event.name}.",
           page_url: ElixirEventsWeb.SEO.base_url() <> "/events/#{event.slug}/speakers",
           event: event,
           keynote_speakers: keynote_speakers,
           regular_speakers: regular_speakers,
           keynote_profile_ids: keynote_profile_ids,
           talk_counts: talk_counts
         )}
    end
  end
end
