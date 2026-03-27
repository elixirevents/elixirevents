defmodule ElixirEventsWeb.EventLive.ShowCompact do
  @moduledoc """
  Compact layout for meetups, workshops, and other simple events.
  Single-column, Luma-inspired, no sidebar or section nav.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: ElixirEventsWeb.Endpoint,
    router: ElixirEventsWeb.Router,
    statics: ElixirEventsWeb.static_paths()

  import ElixirEventsWeb.BrandComponents
  import ElixirEventsWeb.Helpers

  def render(assigns) do
    show_compact(assigns)
  end

  embed_templates "show_compact.html"
end
