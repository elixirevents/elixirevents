defmodule ElixirEvents.Search.IndexTriggerTest do
  use ElixirEvents.DataCase
  use Oban.Testing, repo: ElixirEvents.Repo, testing: :manual

  alias ElixirEvents.Search.IndexWorker

  import ElixirEvents.DataFixtures

  describe "automatic indexing on insert" do
    test "enqueues upsert job when an event is created" do
      series = event_series_fixture()
      event = event_fixture(series)

      assert_enqueued(
        worker: IndexWorker,
        args: %{action: "upsert", schema: "Event", id: event.id}
      )
    end

    test "enqueues upsert job when a profile is created" do
      profile = profile_fixture()

      assert_enqueued(
        worker: IndexWorker,
        args: %{action: "upsert", schema: "Profile", id: profile.id}
      )
    end

    test "does not enqueue for non-indexable schemas" do
      user = ElixirEvents.AccountsFixtures.user_fixture()
      refute_enqueued(worker: IndexWorker, args: %{action: "upsert", schema: "User", id: user.id})
    end
  end
end
