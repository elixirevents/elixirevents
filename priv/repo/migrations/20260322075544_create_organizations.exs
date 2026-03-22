defmodule ElixirEvents.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :website, :string
      add :logo_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:organizations, [:slug])
  end
end
