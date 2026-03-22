defmodule ElixirEvents.Organizations do
  @moduledoc false

  alias ElixirEvents.Organizations.Organization
  alias ElixirEvents.Repo

  def list_organizations do
    Repo.all(Organization)
  end

  def get_organization_by_slug(slug) do
    Repo.get_by(Organization, slug: slug)
  end

  def create_organization(attrs) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_organization(attrs) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :slug,
      returning: true
    )
  end
end
