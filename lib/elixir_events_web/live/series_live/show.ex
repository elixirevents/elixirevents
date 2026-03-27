defmodule ElixirEventsWeb.SeriesLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Events

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Events.get_event_series_by_slug(slug) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Series not found")
         |> redirect(to: ~p"/events")}

      series ->
        events =
          Events.list_events_for_series(series.id, preload: [:event_series, :cfps])

        {:noreply,
         socket
         |> assign(:page_title, series.name)
         |> assign(
           :page_description,
           series.description || "#{series.name} — Elixir & BEAM event series."
         )
         |> assign(:page_url, ElixirEventsWeb.SEO.base_url() <> "/series/#{series.slug}")
         |> assign(:series, series)
         |> assign(:events, events)}
    end
  end
end
