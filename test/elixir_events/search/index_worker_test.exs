defmodule ElixirEvents.Search.IndexWorkerTest do
  use ElixirEvents.DataCase
  use Oban.Testing, repo: ElixirEvents.Repo

  alias ElixirEvents.Search.IndexWorker

  import ElixirEvents.DataFixtures

  describe "upsert action" do
    test "enqueues correctly with schema and id" do
      assert {:ok, _} =
               IndexWorker.new(%{action: "upsert", schema: "Event", id: 1})
               |> Oban.insert()

      assert_enqueued(worker: IndexWorker, args: %{action: "upsert", schema: "Event", id: 1})
    end
  end

  describe "delete action" do
    test "enqueues correctly with collection and document_id" do
      assert {:ok, _} =
               IndexWorker.new(%{action: "delete", collection: "events", document_id: "1"})
               |> Oban.insert()

      assert_enqueued(
        worker: IndexWorker,
        args: %{action: "delete", collection: "events", document_id: "1"}
      )
    end
  end
end
