defmodule ElixirEventsWeb.WorkshopLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Workshops

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"event_slug" => event_slug, "slug" => slug}, uri, socket) do
    case Workshops.get_workshop_by_event_and_slug(event_slug, slug,
           preload: [:event, :venue, workshop_trainers: :profile]
         ) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Workshop not found")
         |> push_navigate(to: ~p"/events")}

      workshop ->
        {back_to, back_to_title} = ElixirEventsWeb.Helpers.parse_back_link!(uri)

        {:noreply,
         socket
         |> assign(:page_title, workshop.title)
         |> assign(:page_description, workshop.description)
         |> assign(
           :page_url,
           ElixirEventsWeb.SEO.base_url() <> "/events/#{event_slug}/workshops/#{workshop.slug}"
         )
         |> assign(:workshop, workshop)
         |> assign(:back_to, back_to)
         |> assign(:back_to_title, back_to_title)}
    end
  end
end
