defmodule ElixirEvents.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :name, :string, null: false
      add :handle, :string, null: false
      add :headline, :string
      add :bio, :text
      add :website, :string
      add :avatar_url, :string
      add :is_speaker, :boolean, default: false, null: false
      add :social_links, :map, default: "[]"
      add :user_id, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:profiles, [:handle])
    create index(:profiles, [:user_id])
    create index(:profiles, [:is_speaker], where: "is_speaker = true")
  end
end
