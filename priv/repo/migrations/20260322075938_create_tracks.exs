defmodule ElixirEvents.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add :event_id, :integer, null: false
      add :name, :string, null: false
      add :color, :string
      add :position, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:tracks, [:event_id])
  end
end
