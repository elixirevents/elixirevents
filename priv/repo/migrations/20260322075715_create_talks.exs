defmodule ElixirEvents.Repo.Migrations.CreateTalks do
  use Ecto.Migration

  def change do
    create table(:talks) do
      add :event_id, :integer, null: false
      add :title, :string, null: false
      add :slug, :string, null: false
      add :abstract, :text
      add :kind, :string, null: false
      add :language, :string, default: "en"
      add :level, :string
      add :duration, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:talks, [:event_id])
    create unique_index(:talks, [:event_id, :slug])
  end
end
