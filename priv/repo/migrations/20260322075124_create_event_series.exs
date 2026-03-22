defmodule ElixirEvents.Repo.Migrations.CreateEventSeries do
  use Ecto.Migration

  def change do
    create table(:event_series) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :kind, :string, null: false
      add :frequency, :string
      add :language, :string, default: "en"
      add :website, :string
      add :color, :string
      add :ended, :boolean, default: false
      add :social_links, :map, default: "[]"

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:event_series, [:slug])
  end
end
