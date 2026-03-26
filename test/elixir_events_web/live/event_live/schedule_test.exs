defmodule ElixirEventsWeb.EventLive.ScheduleTest do
  use ElixirEventsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ElixirEvents.DataFixtures

  alias ElixirEvents.Program

  describe "Schedule sub-page" do
    setup do
      series = event_series_fixture()
      event = event_fixture(series, %{name: "Sched Conf", slug: "sched-conf"})
      _talk = talk_fixture(event, %{title: "Great Talk", slug: "great-talk"})

      {:ok, track} =
        Program.create_track(%{
          event_id: event.id,
          name: "Main Stage",
          color: "#6B46C1",
          position: 1
        })

      {:ok, day} =
        Program.create_schedule_day(%{
          event_id: event.id,
          date: ~D[2026-01-01],
          name: "Day 1",
          position: 1
        })

      {:ok, talk_slot} =
        Program.create_time_slot(%{
          schedule_day_id: day.id,
          start_time: ~T[09:00:00],
          end_time: ~T[10:00:00]
        })

      {:ok, break_slot} =
        Program.create_time_slot(%{
          schedule_day_id: day.id,
          start_time: ~T[10:00:00],
          end_time: ~T[10:30:00]
        })

      {:ok, _talk_session} =
        Program.create_session(%{
          event_id: event.id,
          time_slot_id: talk_slot.id,
          track_id: track.id,
          title: "Great Talk",
          kind: :talk,
          position: 1
        })

      {:ok, _break_session} =
        Program.create_session(%{
          event_id: event.id,
          time_slot_id: break_slot.id,
          title: "Coffee Break",
          kind: :break,
          position: 1
        })

      %{event: event, day: day, track: track}
    end

    test "renders schedule with day tabs", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events/sched-conf/schedule")
      assert html =~ "Day 1"
      assert html =~ "Great Talk"
      assert html =~ "Main Stage"
    end

    test "renders breaks", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events/sched-conf/schedule")
      assert html =~ "Coffee Break"
    end

    test "renders time slots", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/events/sched-conf/schedule")
      assert html =~ "09:00"
      assert html =~ "10:00"
    end

    test "redirects when no event found", %{conn: conn} do
      assert {:error, {:live_redirect, _}} = live(conn, ~p"/events/nope/schedule")
    end
  end
end
