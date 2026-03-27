defmodule ElixirEvents.Events.EventStatusWorkerTest do
  use ElixirEvents.DataCase, async: true
  use Oban.Testing, repo: ElixirEvents.Repo

  alias ElixirEvents.Events
  alias ElixirEvents.Events.EventStatusWorker

  @valid_event_attrs %{
    name: "Test Event",
    slug: "test-event",
    kind: :conference,
    status: :confirmed,
    format: :in_person,
    start_date: ~D[2025-08-27],
    end_date: ~D[2025-08-29],
    timezone: "America/Chicago"
  }

  test "transitions confirmed events to ongoing then completed" do
    today = Date.utc_today()
    past_date = Date.add(today, -5)

    {:ok, _} =
      Events.create_event(%{
        @valid_event_attrs
        | slug: "currently-running",
          status: :confirmed,
          start_date: today,
          end_date: Date.add(today, 2)
      })

    {:ok, _} =
      Events.create_event(%{
        @valid_event_attrs
        | slug: "already-ended",
          status: :confirmed,
          start_date: Date.add(past_date, -2),
          end_date: past_date
      })

    assert :ok = perform_job(EventStatusWorker, %{})
    assert Events.get_event_by_slug("currently-running").status == :ongoing
    assert Events.get_event_by_slug("already-ended").status == :completed
  end

  test "returns ok when no events to update" do
    assert :ok = perform_job(EventStatusWorker, %{})
  end
end
