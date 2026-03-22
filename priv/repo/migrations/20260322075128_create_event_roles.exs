defmodule ElixirEvents.Repo.Migrations.CreateEventRoles do
  use Ecto.Migration

  def change do
    create table(:event_roles) do
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :role, :string, null: false
      add :position, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:event_roles, [:event_id])
  end
end
