defmodule ElixirEvents.Repo.Migrations.AddLocationToProfiles do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :city, :string
      add :country_code, :string, size: 2
    end
  end
end
