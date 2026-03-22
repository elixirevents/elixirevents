defmodule ElixirEventsWeb.TalkLiveTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ElixirEvents.{Events, Talks}

  defp create_event_and_talk(_) do
    {:ok, event} =
      Events.create_event(%{
        name: "ElixirConf 2025",
        slug: "elixirconf-2025",
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2025-08-27],
        end_date: ~D[2025-08-29],
        timezone: "America/Chicago"
      })

    {:ok, talk} =
      Talks.create_talk(%{
        event_id: event.id,
        title: "Opening Keynote",
        slug: "opening-keynote",
        kind: :keynote
      })

    %{event: event, talk: talk}
  end

  describe "Index" do
    setup [:create_event_and_talk]

    test "renders talks page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/talks")
      assert html =~ "Opening Keynote"
    end

    test "filters by published", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/talks?filter=published")
      assert html =~ "Talks"
    end

    test "filters by scheduled", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/talks?filter=scheduled")
      assert html =~ "Talks"
    end

    test "sorts by title", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/talks?sort=title")
      assert html =~ "Talks"
    end

    test "handles pagination param", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/talks?page=1")
      assert html =~ "Talks"
    end
  end

  describe "Show" do
    setup [:create_event_and_talk]

    test "renders talk detail page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/talks/elixirconf-2025/opening-keynote")
      assert html =~ "Opening Keynote"
    end

    test "redirects for non-existent talk", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/talks"}}} =
               live(conn, ~p"/talks/elixirconf-2025/nonexistent")
    end
  end
end
