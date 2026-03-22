defmodule ElixirEvents.ImportTest do
  use ElixirEvents.DataCase

  alias ElixirEvents.{
    Events,
    Organizations,
    Profiles,
    Program,
    Sponsorship,
    Submissions,
    Talks,
    Topics,
    Venues
  }

  test "imports all sample data from priv/data" do
    data_dir = Application.app_dir(:elixir_events, "priv/data")
    assert :ok = ElixirEvents.Import.run(data_dir)

    # Verify global entities
    assert length(Topics.list_topics()) >= 10
    assert length(Profiles.list_profiles()) >= 5
    assert length(Organizations.list_organizations()) >= 3
    assert Venues.list_venues() != []

    # Verify series
    series = Events.get_event_series_by_slug("elixirconf")
    assert series != nil
    assert series.kind == :conference

    # Verify event
    event = Events.get_event_by_slug("elixirconf-us-2024")
    assert event != nil
    assert event.event_series_id == series.id
    assert event.venue_id != nil

    # Verify talks
    talks = Talks.list_talks_for_event(event.id)
    assert length(talks) >= 3

    # Verify schedule
    days = Program.list_schedule_days(event.id)
    assert days != []

    tracks = Program.list_tracks(event.id)
    assert length(tracks) >= 2

    sessions = Program.list_sessions(event.id)
    assert length(sessions) >= 3

    # Verify sponsors
    tiers = Sponsorship.list_sponsor_tiers(event.id)
    assert length(tiers) >= 2

    # Verify CFPs
    cfps = Submissions.list_cfps(event.id)
    assert cfps != []

    # Verify idempotency — run again
    assert :ok = ElixirEvents.Import.run(data_dir)
    assert length(Topics.list_topics()) >= 10
  end
end
