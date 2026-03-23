defmodule ElixirEventsWeb.PageController do
  use ElixirEventsWeb, :controller

  alias ElixirEvents.{Events, Profiles, Talks, Topics}

  def contribute(conn, _params) do
    render(conn, :contribute)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def home(conn, _params) do
    upcoming_events =
      Events.list_upcoming_events(
        kinds: [:conference, :summit],
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

    conn
    |> put_layout(false)
    |> render(:home,
      upcoming_events: upcoming_events,
      profiles: profiles,
      topics: topics,
      stats: stats
    )
  end
end
