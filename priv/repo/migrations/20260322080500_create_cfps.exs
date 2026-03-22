defmodule ElixirEvents.Repo.Migrations.CreateCfps do
  use Ecto.Migration

  def change do
    create table(:cfps) do
      add :event_id, :integer, null: false
      add :name, :string
      add :url, :string, null: false
      add :description, :text
      add :open_date, :date
      add :close_date, :date

      timestamps(type: :utc_datetime_usec)
    end

    create index(:cfps, [:event_id])
  end
end
