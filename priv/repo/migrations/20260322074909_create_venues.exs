defmodule ElixirEvents.Repo.Migrations.CreateVenues do
  use Ecto.Migration

  def change do
    create table(:venues) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :street, :string
      add :city, :string
      add :region, :string
      add :country, :string
      add :country_code, :string
      add :postal_code, :string
      add :latitude, :decimal, precision: 10, scale: 7
      add :longitude, :decimal, precision: 10, scale: 7
      add :website, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:venues, [:slug])
    create index(:venues, [:city, :country_code])
  end
end
