defmodule ElixirEvents.Repo.Migrations.CreateTalkTopics do
  use Ecto.Migration

  def change do
    create table(:talk_topics) do
      add :talk_id, :integer, null: false
      add :topic_id, references(:topics, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:talk_topics, [:talk_id, :topic_id])
    create index(:talk_topics, [:topic_id])
    create index(:talk_topics, [:talk_id])
  end
end
