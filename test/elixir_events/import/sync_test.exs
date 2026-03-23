defmodule ElixirEvents.Import.SyncTest do
  use ElixirEvents.DataCase

  import ElixirEvents.AccountsFixtures
  import ElixirEvents.DataFixtures

  alias ElixirEvents.{Events, Organizations, Profiles, Talks, Topics, Venues}
  alias ElixirEvents.Import.Sync

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

  describe "orphan cleanup" do
    test "delete_orphaned_talks removes talks not in YAML slugs" do
      series = event_series_fixture()
      event = event_fixture(series)
      talk_fixture(event, %{slug: "keep-me", title: "Keep Me"})
      talk_fixture(event, %{slug: "remove-me", title: "Remove Me"})

      {deleted, _} = Talks.delete_orphaned_talks(event.id, ["keep-me"])
      assert deleted == 1

      assert Talks.get_talk_by_slug(event.id, "keep-me") != nil
      assert Talks.get_talk_by_slug(event.id, "remove-me") == nil
    end

    test "delete_orphaned_events removes events not in YAML slugs" do
      series = event_series_fixture()
      event_fixture(series, %{slug: "keep-event", name: "Keep"})
      event_fixture(series, %{slug: "remove-event", name: "Remove"})

      {deleted, _} = Events.delete_orphaned_events(series.id, ["keep-event"])
      assert deleted == 1

      assert Events.get_event_by_slug("keep-event") != nil
      assert Events.get_event_by_slug("remove-event") == nil
    end

    @tag :tmp_dir
    test "talks import deletes orphaned talks after upserting", %{tmp_dir: tmp_dir} do
      series = event_series_fixture()
      event = event_fixture(series)
      talk_fixture(event, %{slug: "old-slug-talk", title: "Old Talk"})

      event_dir = Path.join(tmp_dir, "test-event")
      File.mkdir_p!(event_dir)

      write_yaml_file(event_dir, "talks.yml", """
      - title: "New Talk"
        slug: "new-slug-talk"
        kind: talk
      """)

      ElixirEvents.Import.Talks.run(event_dir, event)

      assert Talks.get_talk_by_slug(event.id, "new-slug-talk") != nil
      assert Talks.get_talk_by_slug(event.id, "old-slug-talk") == nil
    end

    @tag :tmp_dir
    test "sync deletes event when YAML file is removed", %{tmp_dir: tmp_dir} do
      series = event_series_fixture(%{slug: "test-series"})
      event_fixture(series, %{slug: "removed-event", name: "Removed"})
      event_fixture(series, %{slug: "kept-event", name: "Kept"})

      # Create series dir with only one event (the other is "removed")
      series_dir = Path.join(tmp_dir, "test-series")
      File.mkdir_p!(Path.join(series_dir, "kept-event"))

      write_yaml_file(series_dir, "series.yml", """
      name: "Test Series"
      slug: "test-series"
      kind: conference
      """)

      write_yaml_file(Path.join(series_dir, "kept-event"), "event.yml", """
      name: "Kept"
      slug: "kept-event"
      kind: conference
      status: confirmed
      format: in_person
      start_date: "2026-01-01"
      end_date: "2026-01-02"
      timezone: "UTC"
      """)

      # Manifest says both events changed, but removed-event has no file on disk
      write_manifest(tmp_dir, [
        "priv/data/test-series/series.yml",
        "priv/data/test-series/kept-event/event.yml",
        "priv/data/test-series/removed-event/event.yml"
      ])

      assert :ok = Sync.run(tmp_dir)

      assert Events.get_event_by_slug("kept-event") != nil
      assert Events.get_event_by_slug("removed-event") == nil
    end
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

  defp write_yaml_file(dir, filename, content) do
    File.write!(Path.join(dir, filename), content)
  end

  defp write_manifest(dir, files) do
    File.write!(Path.join(dir, ".changed_files"), Enum.join(files, "\n"))
  end
end
