defmodule ElixirEvents.Repo.Migrations.CreateEventTopics do
  use Ecto.Migration

  def change do
    create table(:event_topics) do
      add :event_id, :integer, null: false
      add :topic_id, references(:topics, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:event_topics, [:event_id, :topic_id])
    create index(:event_topics, [:topic_id])
    create index(:event_topics, [:event_id])
  end
end
