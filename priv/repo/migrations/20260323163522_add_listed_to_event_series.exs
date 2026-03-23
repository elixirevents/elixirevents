defmodule ElixirEvents.Repo.Migrations.AddListedToEventSeries do
  use Ecto.Migration

  def change do
    alter table(:event_series) do
      add :listed, :boolean, default: true, null: false
    end
  end
end
