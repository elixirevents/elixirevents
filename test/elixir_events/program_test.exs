defmodule ElixirEvents.ProgramTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Program}

  defp create_event(_) do
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

    %{event: event}
  end

  describe "list_schedule_days/1" do
    setup [:create_event]

    test "returns schedule days for an event ordered by position", %{event: event} do
      {:ok, _} =
        Program.create_schedule_day(%{
          event_id: event.id,
          date: ~D[2025-08-28],
          name: "Day 2",
          position: 2
        })

      {:ok, _} =
        Program.create_schedule_day(%{
          event_id: event.id,
          date: ~D[2025-08-27],
          name: "Day 1",
          position: 1
        })

      days = Program.list_schedule_days(event.id)
      assert [%{name: "Day 1"}, %{name: "Day 2"}] = days
    end
  end

  describe "list_tracks/1" do
    setup [:create_event]

    test "returns tracks for an event ordered by position", %{event: event} do
      {:ok, _} = Program.create_track(%{event_id: event.id, name: "Track B", position: 2})
      {:ok, _} = Program.create_track(%{event_id: event.id, name: "Track A", position: 1})

      tracks = Program.list_tracks(event.id)
      assert [%{name: "Track A"}, %{name: "Track B"}] = tracks
    end
  end

  describe "list_sessions/1" do
    setup [:create_event]

    test "returns sessions for an event", %{event: event} do
      {:ok, _} = Program.create_session(%{event_id: event.id, title: "Break", kind: :break})
      assert [%{title: "Break"}] = Program.list_sessions(event.id)
    end
  end

  describe "schedule_days" do
    setup [:create_event]

    test "creates a schedule day", %{event: event} do
      assert {:ok, day} =
               Program.create_schedule_day(%{
                 event_id: event.id,
                 date: ~D[2025-08-27],
                 name: "Day 1",
                 position: 1
               })

      assert day.name == "Day 1"
    end

    test "enforces unique date per event", %{event: event} do
      attrs = %{event_id: event.id, date: ~D[2025-08-27], name: "Day 1"}
      {:ok, _} = Program.create_schedule_day(attrs)
      assert {:error, changeset} = Program.create_schedule_day(attrs)
      assert "has already been taken" in errors_on(changeset).date
    end
  end

  describe "tracks" do
    setup [:create_event]

    test "creates a track", %{event: event} do
      assert {:ok, track} =
               Program.create_track(%{
                 event_id: event.id,
                 name: "Main Stage",
                 color: "#6B46C1",
                 position: 1
               })

      assert track.name == "Main Stage"
    end
  end

  describe "time_slots" do
    setup [:create_event]

    test "creates a time slot for a day", %{event: event} do
      {:ok, day} =
        Program.create_schedule_day(%{
          event_id: event.id,
          date: ~D[2025-08-27],
          name: "Day 1"
        })

      assert {:ok, slot} =
               Program.create_time_slot(%{
                 schedule_day_id: day.id,
                 start_time: ~T[09:00:00],
                 end_time: ~T[10:00:00]
               })

      assert slot.start_time == ~T[09:00:00]
    end
  end

  describe "sessions" do
    setup [:create_event]

    test "creates a session (break, no talk)", %{event: event} do
      assert {:ok, session} =
               Program.create_session(%{
                 event_id: event.id,
                 title: "Coffee Break",
                 kind: :break
               })

      assert session.kind == :break
      assert session.talk_id == nil
    end

    test "creates a session linked to a talk", %{event: event} do
      {:ok, talk} =
        ElixirEvents.Talks.create_talk(%{
          event_id: event.id,
          title: "Keynote",
          slug: "keynote",
          kind: :keynote
        })

      {:ok, day} =
        Program.create_schedule_day(%{event_id: event.id, date: ~D[2025-08-27], name: "Day 1"})

      {:ok, slot} =
        Program.create_time_slot(%{
          schedule_day_id: day.id,
          start_time: ~T[09:00:00],
          end_time: ~T[10:00:00]
        })

      {:ok, track} =
        Program.create_track(%{event_id: event.id, name: "Main Stage"})

      assert {:ok, session} =
               Program.create_session(%{
                 event_id: event.id,
                 talk_id: talk.id,
                 time_slot_id: slot.id,
                 track_id: track.id,
                 title: "Keynote",
                 kind: :keynote
               })

      assert session.talk_id == talk.id
      assert session.time_slot_id == slot.id
      assert session.track_id == track.id
    end
  end

  describe "replace_schedule/2" do
    setup [:create_event]

    test "replaces all schedule data for an event", %{event: event} do
      {:ok, _day} =
        Program.create_schedule_day(%{event_id: event.id, date: ~D[2025-08-27], name: "Old"})

      {:ok, _track} = Program.create_track(%{event_id: event.id, name: "Old Track"})

      schedule_attrs = %{
        days: [%{date: ~D[2025-08-28], name: "Day 1", position: 1}],
        tracks: [%{name: "Main Stage", color: "#6B46C1", position: 1}],
        time_slots: %{~D[2025-08-28] => [%{start_time: ~T[09:00:00], end_time: ~T[10:00:00]}]},
        sessions: []
      }

      assert {:ok, result} = Program.replace_schedule(event.id, schedule_attrs)
      assert length(result.days) == 1
      assert hd(result.days).name == "Day 1"
      assert length(result.tracks) == 1
    end
  end
end
