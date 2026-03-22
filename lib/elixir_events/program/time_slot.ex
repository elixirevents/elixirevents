defmodule ElixirEvents.Program.TimeSlot do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(schedule_day_id start_time end_time)a
  @required ~w(schedule_day_id start_time end_time)a

  schema "time_slots" do
    field :start_time, :time
    field :end_time, :time

    belongs_to :schedule_day, ElixirEvents.Program.ScheduleDay
    has_many :sessions, ElixirEvents.Program.Session

    timestamps()
  end

  def changeset(time_slot, attrs) do
    time_slot
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:schedule_day_id)
  end
end
