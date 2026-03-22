defmodule ElixirEvents.Repo.Migrations.CreateTalkSpeakers do
  use Ecto.Migration

  def change do
    create table(:talk_speakers) do
      add :talk_id, references(:talks, on_delete: :delete_all), null: false
      add :profile_id, :integer, null: false
      add :role, :string, default: "speaker"
      add :position, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:talk_speakers, [:talk_id])
    create index(:talk_speakers, [:profile_id])
    create unique_index(:talk_speakers, [:talk_id, :profile_id])
  end
end
