defmodule ElixirEvents.Repo.Migrations.CreateScheduleDays do
  use Ecto.Migration

  def change do
    create table(:schedule_days) do
      add :event_id, :integer, null: false
      add :date, :date, null: false
      add :name, :string
      add :position, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:schedule_days, [:event_id])
    create unique_index(:schedule_days, [:event_id, :date])
  end
end
