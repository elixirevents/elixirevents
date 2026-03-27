defmodule ElixirEventsWeb.EventLive.ShowConference do
  @moduledoc """
  Conference layout template for the event show page.
  Full layout with section nav, sidebar, speaker previews, schedule, etc.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: ElixirEventsWeb.Endpoint,
    router: ElixirEventsWeb.Router,
    statics: ElixirEventsWeb.static_paths()

  import ElixirEventsWeb.BrandComponents
  import ElixirEventsWeb.Helpers

  def render(assigns) do
    show_conference(assigns)
  end

  embed_templates "show_conference.html"
end
