defmodule ElixirEvents.Venues do
  @moduledoc false

  alias ElixirEvents.Repo
  alias ElixirEvents.Venues.Venue

  def list_venues do
    Repo.all(Venue)
  end

  def get_venue_by_slug(slug) do
    Repo.get_by(Venue, slug: slug)
  end

  def create_venue(attrs) do
    %Venue{}
    |> Venue.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_venue(attrs) do
    %Venue{}
    |> Venue.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :slug,
      returning: true
    )
  end
end
