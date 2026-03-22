defmodule ElixirEvents.Program.Track do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(event_id name color position)a
  @required ~w(event_id name)a

  schema "tracks" do
    field :event_id, :integer
    field :name, :string
    field :color, :string
    field :position, :integer

    timestamps()
  end

  def changeset(track, attrs) do
    track
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
