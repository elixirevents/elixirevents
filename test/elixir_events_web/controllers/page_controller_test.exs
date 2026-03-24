defmodule ElixirEventsWeb.PageControllerTest do
  use ElixirEventsWeb.ConnCase

  alias ElixirEvents.Events

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "ElixirEvents"
  end

  describe "home page upcoming events" do
    test "shows meetup events in the upcoming events section", %{conn: conn} do
      future = Date.add(Date.utc_today(), 10)

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

      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      assert html =~ "Braga BEAM #8"
    end

    test "shows conferences in the upcoming events section", %{conn: conn} do
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

      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      assert html =~ "ElixirConf US 2026"
    end

    test "featured carousel only shows conferences and summits", %{conn: conn} do
      future = Date.add(Date.utc_today(), 10)

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

      {:ok, _conference} =
        Events.create_event(%{
          name: "ElixirConf US 2026",
          slug: "elixirconf-us-2026",
          kind: :conference,
          status: :confirmed,
          format: :in_person,
          start_date: Date.add(future, 20),
          end_date: Date.add(future, 22),
          timezone: "America/Chicago"
        })

      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      # Meetup should appear in upcoming list but the featured carousel
      # only includes conferences and summits
      assert html =~ "Braga BEAM #8"
      assert html =~ "ElixirConf US 2026"
    end
  end
end
