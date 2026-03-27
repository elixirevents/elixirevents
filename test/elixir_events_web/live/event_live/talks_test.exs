defmodule ElixirEventsWeb.EventLive.TalksTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.DataFixtures

  describe "Talks sub-page" do
    test "renders all talks for an event", %{conn: conn} do
      series = event_series_fixture()
      event = event_fixture(series, %{name: "Test Conf", slug: "test-conf"})
      _keynote = talk_fixture(event, %{title: "Opening Keynote", slug: "keynote", kind: :keynote})
      _talk1 = talk_fixture(event, %{title: "Building APIs", slug: "apis", kind: :talk})
      _talk2 = talk_fixture(event, %{title: "Testing Tips", slug: "testing", kind: :talk})

      {:ok, _lv, html} = live(conn, ~p"/events/test-conf/talks")
      assert html =~ "Opening Keynote"
      assert html =~ "Building APIs"
      assert html =~ "Testing Tips"
    end

    test "shows breadcrumb with event name", %{conn: conn} do
      series = event_series_fixture()
      _event = event_fixture(series, %{name: "My Conf", slug: "my-conf"})

      {:ok, _lv, html} = live(conn, ~p"/events/my-conf/talks")
      assert html =~ "My Conf"
      assert html =~ "Talks"
    end

    test "filters by kind", %{conn: conn} do
      series = event_series_fixture()
      event = event_fixture(series, %{name: "Filter Conf", slug: "filter-conf"})
      _keynote = talk_fixture(event, %{title: "The Keynote", slug: "keynote", kind: :keynote})
      _talk = talk_fixture(event, %{title: "Regular Talk", slug: "regular", kind: :talk})

      {:ok, lv, _html} = live(conn, ~p"/events/filter-conf/talks")

      html =
        lv |> element("[phx-click='filter-kind'][phx-value-kind='keynote']") |> render_click()

      assert html =~ "The Keynote"
      refute html =~ "Regular Talk"
    end

    test "redirects for non-existent event", %{conn: conn} do
      assert {:error, {:live_redirect, _}} = live(conn, ~p"/events/nope/talks")
    end
  end
end
