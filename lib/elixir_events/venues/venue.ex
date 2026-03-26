defmodule ElixirEvents.Venues.Venue do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(name slug street city region country country_code postal_code latitude longitude website description)a
  @required ~w(name slug)a

  schema "venues" do
    field :name, :string
    field :slug, :string
    field :street, :string
    field :city, :string
    field :region, :string
    field :country, :string
    field :country_code, :string
    field :postal_code, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :website, :string
    field :description, :string

    timestamps()
  end

  def changeset(venue, attrs) do
    venue
    |> cast(attrs, @permitted)
    |> Slug.maybe_generate_slug()
    |> validate_required(@required)
    |> Slug.validate_slug_format()
    |> unique_constraint(:slug)
  end
end
