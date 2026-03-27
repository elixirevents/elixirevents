defmodule ElixirEvents.Repo.Migrations.AddDescriptionToVenues do
  use Ecto.Migration

  def change do
    alter table(:venues) do
      add :description, :text
    end
  end
end
