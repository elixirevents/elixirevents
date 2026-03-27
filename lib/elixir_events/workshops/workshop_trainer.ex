defmodule ElixirEvents.Workshops.WorkshopTrainer do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(workshop_id profile_id position)a
  @required ~w(workshop_id profile_id)a

  schema "workshop_trainers" do
    field :position, :integer

    belongs_to :workshop, ElixirEvents.Workshops.Workshop
    belongs_to :profile, ElixirEvents.Profiles.Profile

    timestamps()
  end

  def changeset(workshop_trainer, attrs) do
    workshop_trainer
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:workshop_id)
    |> unique_constraint([:workshop_id, :profile_id])
  end
end
