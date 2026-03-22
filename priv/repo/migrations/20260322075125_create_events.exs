defmodule ElixirEvents.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :event_series_id, references(:event_series, on_delete: :nilify_all)
      add :venue_id, :integer
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :kind, :string, null: false
      add :status, :string, null: false
      add :format, :string, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :timezone, :string, null: false
      add :language, :string, default: "en"
      add :location, :string
      add :website, :string
      add :tickets_url, :string
      add :banner_url, :string
      add :color, :string
      add :social_links, :map, default: "[]"

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:events, [:slug])
    create index(:events, [:start_date])
    create index(:events, [:event_series_id])
    create index(:events, [:venue_id])
  end
end
