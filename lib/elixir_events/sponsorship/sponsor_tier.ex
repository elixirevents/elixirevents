defmodule ElixirEvents.Sponsorship.SponsorTier do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(event_id name level description)a
  @required ~w(event_id name level)a

  schema "sponsor_tiers" do
    field :event_id, :integer
    field :name, :string
    field :level, :integer
    field :description, :string

    has_many :sponsors, ElixirEvents.Sponsorship.Sponsor

    timestamps()
  end

  def changeset(sponsor_tier, attrs) do
    sponsor_tier
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> unique_constraint(:level, name: :sponsor_tiers_event_id_level_index)
  end
end
