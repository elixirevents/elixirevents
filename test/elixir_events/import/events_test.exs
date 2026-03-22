defmodule ElixirEvents.Import.EventsTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Import
  alias ElixirEvents.Venues

  @tag :tmp_dir
  test "imports series and event from directory structure", %{tmp_dir: tmp_dir} do
    # Create venue first
    Venues.upsert_venue(%{name: "Test Venue", slug: "test-venue"})

    # Create series dir
    series_dir = Path.join(tmp_dir, "test-conf")
    event_dir = Path.join(series_dir, "test-conf-2024")
    File.mkdir_p!(event_dir)

    File.write!(Path.join(series_dir, "series.yml"), """
    name: "Test Conf"
    slug: "test-conf"
    kind: conference
    frequency: yearly
    """)

    File.write!(Path.join(event_dir, "event.yml"), """
    name: "Test Conf 2024"
    slug: "test-conf-2024"
    venue_slug: "test-venue"
    kind: conference
    status: completed
    format: in_person
    start_date: "2024-08-28"
    end_date: "2024-08-30"
    timezone: "America/Chicago"
    location: "Orlando, FL"
    """)

    {:ok, series} = Import.Series.run(series_dir)
    assert series.name == "Test Conf"

    {:ok, event} = Import.Events.run(event_dir, series)
    assert event.name == "Test Conf 2024"
    assert event.event_series_id == series.id
    assert event.venue_id != nil
  end
end
