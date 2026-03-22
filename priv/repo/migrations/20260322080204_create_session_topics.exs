defmodule ElixirEvents.Repo.Migrations.CreateSessionTopics do
  use Ecto.Migration

  def change do
    create table(:session_topics) do
      add :session_id, :integer, null: false
      add :topic_id, references(:topics, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:session_topics, [:session_id, :topic_id])
    create index(:session_topics, [:topic_id])
    create index(:session_topics, [:session_id])
  end
end
