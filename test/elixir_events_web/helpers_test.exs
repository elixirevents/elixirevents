defmodule ElixirEventsWeb.HelpersTest do
  use ExUnit.Case, async: true

  alias ElixirEventsWeb.Helpers

  describe "map URL helpers" do
    test "google_maps_url/1 generates correct URL from venue" do
      venue = %{
        latitude: Decimal.new("32.9457"),
        longitude: Decimal.new("-97.0700"),
        name: "Gaylord Texan"
      }

      url = Helpers.google_maps_url(venue)
      assert url == "https://www.google.com/maps/search/?api=1&query=32.9457,-97.0700"
    end

    test "apple_maps_url/1 generates correct URL with encoded name" do
      venue = %{
        latitude: Decimal.new("32.9457"),
        longitude: Decimal.new("-97.0700"),
        name: "Gaylord Texan Resort"
      }

      url = Helpers.apple_maps_url(venue)
      assert url =~ "maps.apple.com"
      assert url =~ "32.9457"
      assert url =~ "Gaylord"
    end

    test "openstreetmap_url/1 generates correct URL" do
      venue = %{
        latitude: Decimal.new("32.9457"),
        longitude: Decimal.new("-97.0700"),
        name: "Test"
      }

      url = Helpers.openstreetmap_url(venue)
      assert url =~ "openstreetmap.org"
      assert url =~ "32.9457"
    end

    test "openstreetmap_embed_url/1 generates embed URL with bbox" do
      venue = %{
        latitude: Decimal.new("32.9457"),
        longitude: Decimal.new("-97.0700"),
        name: "Test"
      }

      url = Helpers.openstreetmap_embed_url(venue)
      assert url =~ "openstreetmap.org/export/embed.html"
      assert url =~ "marker=32.9457"
    end
  end
end
