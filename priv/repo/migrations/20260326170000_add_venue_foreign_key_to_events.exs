defmodule ElixirEvents.Repo.Migrations.AddVenueForeignKeyToEvents do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:events, [:venue_id])

    execute(
      "ALTER TABLE events ADD CONSTRAINT events_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES venues(id)",
      "ALTER TABLE events DROP CONSTRAINT IF EXISTS events_venue_id_fkey"
    )
  end
end
