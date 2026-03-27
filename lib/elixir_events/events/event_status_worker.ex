defmodule ElixirEvents.Events.EventStatusWorker do
  @moduledoc """
  Oban cron worker that runs daily at 01:00 UTC to transition event statuses:

  1. Events whose `start_date` has arrived → `:ongoing`
  2. Events whose `end_date` has passed → `:completed`

  Order matters: we mark ongoing first, then completed, so single-day events
  that ended yesterday go straight to completed.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  alias ElixirEvents.Events
  require Logger

  @impl true
  def perform(%Oban.Job{}) do
    {ongoing_count, _} = Events.start_ongoing_events()
    {completed_count, _} = Events.complete_past_events()

    if ongoing_count > 0, do: Logger.info("Marked #{ongoing_count} event(s) as ongoing")
    if completed_count > 0, do: Logger.info("Marked #{completed_count} event(s) as completed")

    :ok
  end
end
