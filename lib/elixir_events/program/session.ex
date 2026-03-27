defmodule ElixirEvents.Program.Session do
  @moduledoc false

  use ElixirEvents.Schema

  @kinds [:keynote, :talk, :workshop, :panel, :lightning_talk, :break, :social]

  @permitted ~w(event_id talk_id time_slot_id track_id title kind position)a
  @required ~w(event_id title kind)a

  schema "sessions" do
    field :event_id, :integer
    field :title, :string
    field :kind, Ecto.Enum, values: @kinds
    field :position, :integer

    belongs_to :time_slot, ElixirEvents.Program.TimeSlot
    belongs_to :track, ElixirEvents.Program.Track
    belongs_to :talk, ElixirEvents.Talks.Talk

    timestamps()
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:time_slot_id)
    |> foreign_key_constraint(:track_id)
  end
end
