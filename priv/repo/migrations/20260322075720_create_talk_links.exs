defmodule ElixirEvents.Repo.Migrations.CreateTalkLinks do
  use Ecto.Migration

  def change do
    create table(:talk_links) do
      add :talk_id, references(:talks, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :url, :string, null: false
      add :label, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:talk_links, [:talk_id])
  end
end
