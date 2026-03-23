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
      assert {:error, {:redirect, %{to: "/events"}}} =
               live(conn, ~p"/events/nonexistent")
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
