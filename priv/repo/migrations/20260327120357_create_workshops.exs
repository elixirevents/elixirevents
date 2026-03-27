defmodule ElixirEvents.Repo.Migrations.CreateWorkshops do
  use Ecto.Migration

  def change do
    create table(:workshops) do
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :venue_id, references(:venues, on_delete: :nilify_all)
      add :title, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :format, :string
      add :experience_level, :string
      add :target_audience, :text
      add :language, :string, default: "en"
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :booking_url, :string
      add :attendees_only, :boolean, default: false, null: false
      add :agenda, :jsonb, default: "[]"

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:workshops, [:event_id, :slug])
    create index(:workshops, [:event_id])

    create table(:workshop_trainers) do
      add :workshop_id, references(:workshops, on_delete: :delete_all), null: false
      add :profile_id, references(:profiles, on_delete: :delete_all), null: false
      add :position, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:workshop_trainers, [:workshop_id, :profile_id])
    create index(:workshop_trainers, [:profile_id])

    create table(:workshop_topics) do
      add :workshop_id, references(:workshops, on_delete: :delete_all), null: false
      add :topic_id, references(:topics, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:workshop_topics, [:workshop_id, :topic_id])
  end
end
