defmodule ElixirEvents.Repo.Migrations.CreateRecordings do
  use Ecto.Migration

  def change do
    create table(:recordings) do
      add :talk_id, references(:talks, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :external_id, :string
      add :url, :string, null: false
      add :duration, :integer
      add :published_at, :utc_datetime_usec
      add :thumbnail_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:recordings, [:talk_id])

    create unique_index(:recordings, [:provider, :external_id],
             name: :recordings_provider_external_id_index
           )
  end
end
