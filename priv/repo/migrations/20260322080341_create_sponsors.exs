defmodule ElixirEvents.Repo.Migrations.CreateSponsors do
  use Ecto.Migration

  def change do
    create table(:sponsors) do
      add :sponsor_tier_id, references(:sponsor_tiers, on_delete: :delete_all), null: false
      add :organization_id, :integer, null: false
      add :badge, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:sponsors, [:sponsor_tier_id])
    create index(:sponsors, [:organization_id])
    create unique_index(:sponsors, [:sponsor_tier_id, :organization_id])
  end
end
