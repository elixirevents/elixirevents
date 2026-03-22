defmodule ElixirEvents.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :event_id, :integer, null: false
      add :talk_id, :integer
      add :time_slot_id, references(:time_slots, on_delete: :nilify_all)
      add :track_id, references(:tracks, on_delete: :nilify_all)
      add :title, :string, null: false
      add :kind, :string, null: false
      add :position, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:sessions, [:event_id])
    create index(:sessions, [:talk_id])
    create index(:sessions, [:time_slot_id])
    create index(:sessions, [:track_id])
  end
end
