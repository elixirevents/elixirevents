defmodule ElixirEvents.Repo.Migrations.CreateTimeSlots do
  use Ecto.Migration

  def change do
    create table(:time_slots) do
      add :schedule_day_id, references(:schedule_days, on_delete: :delete_all), null: false
      add :start_time, :time, null: false
      add :end_time, :time, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:time_slots, [:schedule_day_id])
  end
end
