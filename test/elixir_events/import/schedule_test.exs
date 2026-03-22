defmodule ElixirEvents.Import.ScheduleTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.{Events, Program, Talks}
  alias ElixirEvents.Import

  setup do
    {:ok, event} =
      Events.create_event(%{
        name: "Conf",
        slug: "conf-sched",
        kind: :conference,
        status: :confirmed,
        format: :in_person,
        start_date: ~D[2025-01-01],
        end_date: ~D[2025-01-02],
        timezone: "UTC"
      })

    {:ok, _talk} =
      Talks.create_talk(%{event_id: event.id, title: "Keynote", slug: "keynote", kind: :keynote})

    %{event: event}
  end

  @tag :tmp_dir
  test "imports schedule with days, tracks, slots, and sessions",
       %{event: event, tmp_dir: tmp_dir} do
    yaml = """
    tracks:
      - name: "Main Stage"
        color: "#6B46C1"
        position: 1

    days:
      - name: "Day 1"
        date: "2025-01-01"
        position: 1
        time_slots:
          - start_time: "09:00"
            end_time: "10:00"
            sessions:
              - talk_slug: "keynote"
                track: "Main Stage"
                kind: keynote
          - start_time: "10:00"
            end_time: "10:15"
            sessions:
              - title: "Break"
                kind: break
    """

    File.write!(Path.join(tmp_dir, "schedule.yml"), yaml)

    assert :ok = Import.Schedule.run(tmp_dir, event)

    days = Program.list_schedule_days(event.id)
    assert length(days) == 1

    tracks = Program.list_tracks(event.id)
    assert length(tracks) == 1

    sessions = Program.list_sessions(event.id)
    assert length(sessions) == 2
  end
end
