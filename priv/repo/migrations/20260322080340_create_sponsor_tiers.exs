defmodule ElixirEvents.Repo.Migrations.CreateSponsorTiers do
  use Ecto.Migration

  def change do
    create table(:sponsor_tiers) do
      add :event_id, :integer, null: false
      add :name, :string, null: false
      add :level, :integer, null: false
      add :description, :text

      timestamps(type: :utc_datetime_usec)
    end

    create index(:sponsor_tiers, [:event_id])
    create unique_index(:sponsor_tiers, [:event_id, :level])
  end
end
