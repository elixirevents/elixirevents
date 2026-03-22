defmodule ElixirEvents.Sponsorship.Sponsor do
  @moduledoc false

  use ElixirEvents.Schema

  @badges [:keynote, :wifi, :coffee, :lanyard, :party]

  @permitted ~w(sponsor_tier_id organization_id badge)a
  @required ~w(sponsor_tier_id organization_id)a

  schema "sponsors" do
    field :badge, Ecto.Enum, values: @badges

    belongs_to :organization, ElixirEvents.Organizations.Organization
    belongs_to :sponsor_tier, ElixirEvents.Sponsorship.SponsorTier

    timestamps()
  end

  def changeset(sponsor, attrs) do
    sponsor
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> foreign_key_constraint(:sponsor_tier_id)
    |> unique_constraint([:sponsor_tier_id, :organization_id])
  end
end
