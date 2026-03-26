defmodule ElixirEventsWeb.EventLiveTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ElixirEvents.Events

  @event_attrs %{
    name: "ElixirConf US 2025",
    slug: "elixirconf-us-2025",
    kind: :conference,
    status: :confirmed,
    format: :in_person,
    start_date: ~D[2025-08-27],
    end_date: ~D[2025-08-29],
    timezone: "America/Chicago"
  }

  defp create_event(_) do
    {:ok, event} = Events.create_event(@event_attrs)
    %{event: event}
  end

  describe "Index" do
    setup [:create_event]

    test "renders events page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events")
      assert html =~ "ElixirConf US 2025"
    end

    test "filters by upcoming", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events?filter=upcoming")
      assert html =~ "Events"
    end

    test "filters by past", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events?filter=past")
      assert html =~ "Events"
    end

    test "ignores invalid filter", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events?filter=bogus")
      assert html =~ "Events"
    end
  end

  describe "Show" do
    setup [:create_event]

    test "renders event detail page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events/elixirconf-us-2025")
      assert html =~ "ElixirConf US 2025"
    end

    test "redirects for non-existent event", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/events"}}} =
               live(conn, ~p"/events/nonexistent")
    end
  end

  describe "Show — enhanced sections" do
    import ElixirEvents.DataFixtures

    test "renders section nav with available sections", %{conn: conn} do
      series = event_series_fixture()

      event =
        event_fixture(series, %{
          name: "Test Conf",
          slug: "test-conf",
          description: "A great conference"
        })

      _talk = talk_fixture(event, %{title: "My Talk", slug: "my-talk"})

      {:ok, _lv, html} = live(conn, ~p"/events/test-conf")
      assert html =~ "section-nav"
      assert html =~ "About"
      assert html =~ "A great conference"
      assert html =~ "Talks"
      assert html =~ "My Talk"
    end

    test "omits sections when no data", %{conn: conn} do
      series = event_series_fixture()

      _event =
        event_fixture(series, %{
          name: "Bare Event",
          slug: "bare-event"
        })

      {:ok, _lv, html} = live(conn, ~p"/events/bare-event")
      assert html =~ "Bare Event"
      refute html =~ "id=\"about\""
      refute html =~ "id=\"schedule\""
      refute html =~ "id=\"sponsors\""
      refute html =~ "id=\"venue\""
    end

    test "renders venue section when venue exists", %{conn: conn} do
      venue =
        venue_fixture(%{
          name: "Cool Center",
          slug: "cool-center",
          city: "Portland",
          country: "United States",
          latitude: Decimal.new("45.52"),
          longitude: Decimal.new("-122.67")
        })

      series = event_series_fixture()

      _event =
        event_fixture(series, %{
          name: "Venue Event",
          slug: "venue-event",
          venue_id: venue.id
        })

      {:ok, _lv, html} = live(conn, ~p"/events/venue-event")
      assert html =~ "Cool Center"
      assert html =~ "Google Maps"
    end

    test "renders tickets CTA when tickets_url present", %{conn: conn} do
      series = event_series_fixture()

      _event =
        event_fixture(series, %{
          name: "Ticket Event",
          slug: "ticket-event",
          tickets_url: "https://tickets.example.com"
        })

      {:ok, _lv, html} = live(conn, ~p"/events/ticket-event")
      assert html =~ "Get Tickets"
      assert html =~ "tickets.example.com"
    end
  end

  describe "meetup events on index" do
    test "all filter shows meetup events alongside conferences", %{conn: conn} do
      future = Date.add(Date.utc_today(), 30)

      {:ok, _conference} =
        Events.create_event(%{
          name: "ElixirConf US 2026",
          slug: "elixirconf-us-2026",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: future,
          end_date: Date.add(future, 2),
          timezone: "America/Chicago"
        })

      {:ok, _meetup} =
        Events.create_event(%{
          name: "Braga BEAM #8",
          slug: "bbug-8",
          kind: :meetup,
          status: :confirmed,
          format: :in_person,
          start_date: Date.add(future, 5),
          end_date: Date.add(future, 5),
          timezone: "Europe/Lisbon"
        })

      {:ok, _lv, html} = live(conn, ~p"/events")
      assert html =~ "ElixirConf US 2026"
      assert html =~ "Braga BEAM #8"
    end

    test "upcoming filter shows meetup events", %{conn: conn} do
      future = Date.add(Date.utc_today(), 30)

      {:ok, _meetup} =
        Events.create_event(%{
          name: "Braga BEAM #8",
          slug: "bbug-8",
          kind: :meetup,
          status: :confirmed,
          format: :in_person,
          start_date: future,
          end_date: future,
          timezone: "Europe/Lisbon"
        })

      {:ok, _lv, html} = live(conn, ~p"/events?filter=upcoming")
      assert html =~ "Braga BEAM #8"
    end

    test "past filter shows past meetup events", %{conn: conn} do
      {:ok, _meetup} =
        Events.create_event(%{
          name: "Braga BEAM #7",
          slug: "bbug-7",
          kind: :meetup,
          status: :completed,
          format: :in_person,
          start_date: ~D[2024-06-15],
          end_date: ~D[2024-06-15],
          timezone: "Europe/Lisbon"
        })

      {:ok, _lv, html} = live(conn, ~p"/events?filter=past")
      assert html =~ "Braga BEAM #7"
    end

    test "meetups appear in correct date order within the same year", %{conn: conn} do
      future = Date.add(Date.utc_today(), 60)

      {:ok, _conference} =
        Events.create_event(%{
          name: "Big Conference",
          slug: "big-conf",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: future,
          end_date: Date.add(future, 2),
          timezone: "America/Chicago"
        })

      {:ok, _meetup} =
        Events.create_event(%{
          name: "Local Meetup",
          slug: "local-meetup",
          kind: :meetup,
          status: :confirmed,
          format: :in_person,
          start_date: Date.add(future, -30),
          end_date: Date.add(future, -30),
          timezone: "Europe/Lisbon"
        })

      {:ok, _lv, html} = live(conn, ~p"/events")

      assert html =~ "Big Conference"
      assert html =~ "Local Meetup"

      meetup_pos = :binary.match(html, "Local Meetup") |> elem(0)
      conf_pos = :binary.match(html, "Big Conference") |> elem(0)

      assert meetup_pos < conf_pos,
             "Meetup (earlier date) should appear before conference (later date) in chronological order within year"
    end
  end

  describe "unlisted series" do
    test "events from unlisted series do not appear on events page", %{conn: conn} do
      {:ok, unlisted} =
        Events.create_event_series(%{
          name: "YOW!",
          slug: "yow",
          kind: :conference,
          listed: false
        })

      future = Date.add(Date.utc_today(), 30)

      {:ok, _} =
        Events.create_event(%{
          name: "YOW! 2026",
          slug: "yow-2026",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: future,
          end_date: Date.add(future, 2),
          timezone: "Australia/Sydney",
          event_series_id: unlisted.id
        })

      {:ok, _lv, html} = live(conn, ~p"/events")
      refute html =~ "YOW! 2026"
    end
  end

  describe "Series Show" do
    test "renders series page with events", %{conn: conn} do
      {:ok, series} =
        Events.create_event_series(%{
          name: "ElixirConf",
          slug: "elixirconf",
          kind: :conference,
          frequency: :yearly
        })

      {:ok, _event} =
        Events.create_event(Map.put(@event_attrs, :event_series_id, series.id))

      {:ok, _lv, html} = live(conn, ~p"/series/elixirconf")
      assert html =~ "ElixirConf"
    end

    test "redirects for non-existent series", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/events"}}} =
               live(conn, ~p"/series/nonexistent")
    end
  end
end
