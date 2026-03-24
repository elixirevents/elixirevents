defmodule ElixirEventsWeb.HomeLive do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.{Events, Profiles, Talks, Topics}

  @impl true
  def mount(_params, _session, socket) do
    featured_events =
      Events.list_upcoming_events(
        kinds: [:conference, :summit],
        preload: [:event_series, :cfps],
        limit: 6
      )

    upcoming_events =
      Events.list_upcoming_events(
        preload: [:event_series, :cfps],
        limit: 6
      )

    profiles =
      Profiles.list_profiles(
        speakers_only: true,
        with_talk_count: true,
        order_by: :talk_count_desc,
        limit: 8
      )

    topics =
      Topics.list_topics(with_counts: true)

    stats = %{
      events: Events.count_events(),
      speakers: Profiles.count_profiles(speakers_only: true),
      talks: Talks.count_talks(),
      topics: Topics.count_topics()
    }

    {:ok,
     assign(socket,
       featured_events: featured_events,
       upcoming_events: upcoming_events,
       profiles: profiles,
       topics: topics,
       stats: stats
     ), layout: false}
  end
end
