defmodule ElixirEvents.Repo.Migrations.CreateEventLinks do
  use Ecto.Migration

  def change do
    create table(:event_links) do
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :url, :string, null: false
      add :label, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:event_links, [:event_id])
  end
end
