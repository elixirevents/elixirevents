defmodule ElixirEvents.VenuesTest do
  use ElixirEvents.DataCase, async: true

  alias ElixirEvents.Venues

  @valid_attrs %{
    name: "Gaylord Texan",
    slug: "gaylord-texan",
    city: "Grapevine",
    country: "United States",
    country_code: "US"
  }

  describe "create_venue/1" do
    test "creates a venue with valid attrs" do
      assert {:ok, venue} = Venues.create_venue(@valid_attrs)
      assert venue.name == "Gaylord Texan"
      assert venue.slug == "gaylord-texan"
      assert venue.city == "Grapevine"
    end

    test "requires name and slug" do
      assert {:error, changeset} = Venues.create_venue(%{})
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).slug
    end

    test "enforces unique slug" do
      assert {:ok, _} = Venues.create_venue(@valid_attrs)
      assert {:error, changeset} = Venues.create_venue(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "list_venues/0" do
    test "returns all venues" do
      {:ok, venue} = Venues.create_venue(@valid_attrs)
      assert Venues.list_venues() == [venue]
    end
  end

  describe "get_venue_by_slug/1" do
    test "returns the venue with the given slug" do
      {:ok, venue} = Venues.create_venue(@valid_attrs)
      assert Venues.get_venue_by_slug("gaylord-texan") == venue
    end

    test "returns nil for non-existent slug" do
      assert Venues.get_venue_by_slug("nonexistent") == nil
    end
  end

  describe "upsert_venue/1" do
    test "inserts a new venue" do
      assert {:ok, venue} = Venues.upsert_venue(@valid_attrs)
      assert venue.name == "Gaylord Texan"
    end

    test "updates an existing venue by slug" do
      {:ok, _} = Venues.upsert_venue(@valid_attrs)
      {:ok, updated} = Venues.upsert_venue(%{name: "Gaylord Texan Resort", slug: "gaylord-texan"})
      assert updated.name == "Gaylord Texan Resort"
      assert [_only_one] = Venues.list_venues()
    end
  end

  describe "venue description" do
    test "upsert_venue/1 stores description field" do
      {:ok, venue} =
        Venues.upsert_venue(%{
          name: "Test Venue",
          slug: "test-venue",
          city: "Portland",
          description: "A beautiful conference center in downtown Portland."
        })

      assert venue.description == "A beautiful conference center in downtown Portland."
    end

    test "upsert_venue/1 works without description" do
      {:ok, venue} =
        Venues.upsert_venue(%{
          name: "Minimal Venue",
          slug: "minimal-venue"
        })

      assert venue.description == nil
    end
  end
end
