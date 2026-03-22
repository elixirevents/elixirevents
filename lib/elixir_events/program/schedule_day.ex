defmodule ElixirEvents.Program.ScheduleDay do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(event_id date name position)a
  @required ~w(event_id date)a

  schema "schedule_days" do
    field :event_id, :integer
    field :date, :date
    field :name, :string
    field :position, :integer

    has_many :time_slots, ElixirEvents.Program.TimeSlot

    timestamps()
  end

  def changeset(schedule_day, attrs) do
    schedule_day
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> unique_constraint(:date, name: :schedule_days_event_id_date_index)
  end
end
