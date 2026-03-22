defmodule ElixirEvents.Events.EventRole do
  @moduledoc false

  use ElixirEvents.Schema

  @roles [:organizer, :mc, :volunteer, :program_committee]

  @permitted ~w(event_id name role position)a
  @required ~w(event_id name role)a

  schema "event_roles" do
    field :name, :string
    field :role, Ecto.Enum, values: @roles
    field :position, :integer

    belongs_to :event, ElixirEvents.Events.Event

    timestamps()
  end

  def changeset(event_role, attrs) do
    event_role
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:event_id)
  end
end
