defmodule ElixirEvents.Import.SyncTest do
  use ElixirEvents.DataCase

  import ElixirEvents.AccountsFixtures
  import ElixirEvents.DataFixtures

  alias ElixirEvents.Import.Sync
  alias ElixirEvents.{Organizations, Profiles, Topics, Venues}

  @tag :tmp_dir
  test "noop when no manifest exists", %{tmp_dir: tmp_dir} do
    assert :noop = Sync.run(tmp_dir)
  end

  @tag :tmp_dir
  test "noop when manifest is empty", %{tmp_dir: tmp_dir} do
    write_manifest(tmp_dir, [])
    assert :noop = Sync.run(tmp_dir)
  end

  @tag :tmp_dir
  test "inserts new profiles from changed speakers.yml", %{tmp_dir: tmp_dir} do
    write_yaml(tmp_dir, "speakers.yml", [
      %{"name" => "Alice", "slug" => "alice", "headline" => "Dev"}
    ])

    write_manifest(tmp_dir, ["priv/data/speakers.yml"])

    assert :ok = Sync.run(tmp_dir)

    profile = Profiles.get_profile_by_handle("alice")
    assert profile.name == "Alice"
    assert profile.headline == "Dev"
  end

  @tag :tmp_dir
  test "skips unchanged profiles", %{tmp_dir: tmp_dir} do
    profile = profile_fixture(%{name: "Bob", handle: "bob", headline: "Eng"})

    write_yaml(tmp_dir, "speakers.yml", [
      %{"name" => "Bob", "slug" => "bob", "headline" => "Eng"}
    ])

    write_manifest(tmp_dir, ["priv/data/speakers.yml"])
    assert :ok = Sync.run(tmp_dir)

    refreshed = Profiles.get_profile_by_handle("bob")
    assert profile.updated_at == refreshed.updated_at
  end

  @tag :tmp_dir
  test "updates changed profiles", %{tmp_dir: tmp_dir} do
    profile_fixture(%{name: "Carol", handle: "carol", headline: "Old"})

    write_yaml(tmp_dir, "speakers.yml", [
      %{"name" => "Carol", "slug" => "carol", "headline" => "New"}
    ])

    write_manifest(tmp_dir, ["priv/data/speakers.yml"])
    assert :ok = Sync.run(tmp_dir)

    assert %{headline: "New"} = Profiles.get_profile_by_handle("carol")
  end

  @tag :tmp_dir
  test "skips claimed profiles", %{tmp_dir: tmp_dir} do
    user = user_fixture()
    claimed_profile_fixture(user, %{name: "Dave", handle: "dave", headline: "Mine"})

    write_yaml(tmp_dir, "speakers.yml", [
      %{"name" => "Dave", "slug" => "dave", "headline" => "Overwritten"}
    ])

    write_manifest(tmp_dir, ["priv/data/speakers.yml"])
    assert :ok = Sync.run(tmp_dir)

    assert %{headline: "Mine"} = Profiles.get_profile_by_handle("dave")
  end

  @tag :tmp_dir
  test "syncs topics from changed topics.yml", %{tmp_dir: tmp_dir} do
    write_yaml(tmp_dir, "topics.yml", [
      %{"name" => "LiveView", "slug" => "liveview", "description" => "Real-time UIs"}
    ])

    write_manifest(tmp_dir, ["priv/data/topics.yml"])
    assert :ok = Sync.run(tmp_dir)

    assert %{name: "LiveView"} = Topics.get_topic_by_slug("liveview")
  end

  @tag :tmp_dir
  test "syncs venues from changed venues.yml", %{tmp_dir: tmp_dir} do
    write_yaml(tmp_dir, "venues.yml", [
      %{"name" => "Convention Center", "slug" => "convention-center", "city" => "Portland"}
    ])

    write_manifest(tmp_dir, ["priv/data/venues.yml"])
    assert :ok = Sync.run(tmp_dir)

    assert %{city: "Portland"} = Venues.get_venue_by_slug("convention-center")
  end

  @tag :tmp_dir
  test "syncs organizations from changed organizations.yml", %{tmp_dir: tmp_dir} do
    write_yaml(tmp_dir, "organizations.yml", [
      %{"name" => "Dashbit", "slug" => "dashbit", "website" => "https://dashbit.co"}
    ])

    write_manifest(tmp_dir, ["priv/data/organizations.yml"])
    assert :ok = Sync.run(tmp_dir)

    assert %{website: "https://dashbit.co"} = Organizations.get_organization_by_slug("dashbit")
  end

  @tag :tmp_dir
  test "does not touch globals when only series files changed", %{tmp_dir: tmp_dir} do
    write_manifest(tmp_dir, ["priv/data/elixirconf/series.yml"])
    assert :ok = Sync.run(tmp_dir)
  end

  # -- Helpers --

  defp write_yaml(dir, filename, entries) do
    yaml =
      Enum.map_join(entries, "\n", fn entry ->
        fields =
          Enum.map_join(entry, "\n", fn {key, val} ->
            "  #{key}: #{yaml_value(val)}"
          end)

        "-\n#{fields}"
      end)

    File.write!(Path.join(dir, filename), yaml)
  end

  defp yaml_value(nil), do: "null"
  defp yaml_value(val) when is_binary(val), do: "\"#{val}\""
  defp yaml_value(val), do: "#{val}"

  defp write_manifest(dir, files) do
    File.write!(Path.join(dir, ".changed_files"), Enum.join(files, "\n"))
  end
end
