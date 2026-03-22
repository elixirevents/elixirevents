defmodule ElixirEvents.Organizations.Organization do
  @moduledoc false

  use ElixirEvents.Schema

  @permitted ~w(name slug description website logo_url)a
  @required ~w(name slug)a

  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :website, :string
    field :logo_url, :string

    timestamps()
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, @permitted)
    |> Slug.maybe_generate_slug()
    |> validate_required(@required)
    |> Slug.validate_slug_format()
    |> unique_constraint(:slug)
  end
end
