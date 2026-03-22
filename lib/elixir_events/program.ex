defmodule ElixirEvents.Program do
  @moduledoc false

  import Ecto.Query
  alias ElixirEvents.Program.{ScheduleDay, Session, TimeSlot, Track}
  alias ElixirEvents.Repo

  def list_schedule_days(event_id) do
    ScheduleDay
    |> where(event_id: ^event_id)
    |> order_by(:position)
    |> Repo.all()
  end

  def create_schedule_day(attrs) do
    %ScheduleDay{}
    |> ScheduleDay.changeset(attrs)
    |> Repo.insert()
  end

  def list_tracks(event_id) do
    Track
    |> where(event_id: ^event_id)
    |> order_by(:position)
    |> Repo.all()
  end

  def create_track(attrs) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  def create_time_slot(attrs) do
    %TimeSlot{}
    |> TimeSlot.changeset(attrs)
    |> Repo.insert()
  end

  def list_sessions(event_id) do
    Session
    |> where(event_id: ^event_id)
    |> Repo.all()
  end

  def create_session(attrs) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  def replace_schedule(event_id, schedule_attrs) do
    Repo.transaction(fn ->
      # Delete in reverse dependency order
      from(s in Session, where: s.event_id == ^event_id) |> Repo.delete_all()

      from(ts in TimeSlot,
        join: sd in ScheduleDay,
        on: ts.schedule_day_id == sd.id,
        where: sd.event_id == ^event_id
      )
      |> Repo.delete_all()

      from(sd in ScheduleDay, where: sd.event_id == ^event_id) |> Repo.delete_all()
      from(t in Track, where: t.event_id == ^event_id) |> Repo.delete_all()

      # Re-create tracks
      tracks =
        Enum.map(schedule_attrs.tracks, fn attrs ->
          {:ok, track} = create_track(Map.put(attrs, :event_id, event_id))
          track
        end)

      # Re-create days and time slots
      days =
        Enum.map(schedule_attrs.days, fn day_attrs ->
          {:ok, day} = create_schedule_day(Map.put(day_attrs, :event_id, event_id))

          slots =
            (schedule_attrs.time_slots[day_attrs.date] || [])
            |> Enum.map(fn slot_attrs ->
              {:ok, slot} = create_time_slot(Map.put(slot_attrs, :schedule_day_id, day.id))
              slot
            end)

          Map.put(day, :time_slots, slots)
        end)

      # Create sessions
      sessions =
        Enum.map(schedule_attrs.sessions, fn session_attrs ->
          {:ok, session} = create_session(Map.put(session_attrs, :event_id, event_id))
          session
        end)

      %{days: days, tracks: tracks, sessions: sessions}
    end)
  end
end
