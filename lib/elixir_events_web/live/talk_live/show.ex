defmodule ElixirEventsWeb.TalkLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Talks
  alias ElixirEventsWeb.SEO

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"event_slug" => event_slug, "slug" => slug}, uri, socket) do
    case Talks.get_talk_by_event_and_slug(event_slug, slug,
           preload: [:event, :recordings, :talk_links, talk_speakers: :profile]
         ) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Talk not found")
         |> redirect(to: ~p"/talks")}

      talk ->
        {back_to, back_to_title} = ElixirEventsWeb.Helpers.parse_back_link!(uri)

        {:noreply,
         socket
         |> assign(:page_title, talk.title)
         |> assign(:page_description, talk.abstract)
         |> assign(:page_url, SEO.base_url() <> "/talks/#{talk.event.slug}/#{talk.slug}")
         |> assign(:jsonld, SEO.talk_jsonld(talk))
         |> assign(:talk, talk)
         |> assign(:back_to, back_to)
         |> assign(:back_to_title, back_to_title)}
    end
  end
end
