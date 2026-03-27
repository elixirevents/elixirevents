defmodule ElixirEventsWeb.WorkshopLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Workshops

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"event_slug" => event_slug, "slug" => slug}, _uri, socket) do
    case Workshops.get_workshop_by_event_and_slug(event_slug, slug,
           preload: [:event, :venue, workshop_trainers: :profile]
         ) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Workshop not found")
         |> push_navigate(to: ~p"/events")}

      workshop ->
        {:noreply,
         socket
         |> assign(:page_title, workshop.title)
         |> assign(:workshop, workshop)}
    end
  end
end
