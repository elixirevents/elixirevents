defmodule ElixirEventsWeb.TopicLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Topics

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, uri, socket) do
    case Topics.get_topic_by_slug(slug) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Topic not found")
         |> redirect(to: ~p"/topics")}

      topic ->
        talks =
          Topics.list_talks_for_topic(topic.id,
            preload: [:event, :recordings, talk_speakers: :profile]
          )

        {back_to, back_to_title} = ElixirEventsWeb.Helpers.parse_back_link!(uri)

        {:noreply,
         socket
         |> assign(:page_title, topic.name)
         |> assign(
           :page_description,
           topic.description ||
             "Talks and events about #{topic.name} in the Elixir & BEAM ecosystem."
         )
         |> assign(:page_url, ElixirEventsWeb.SEO.base_url() <> "/topics/#{topic.slug}")
         |> assign(:topic, topic)
         |> assign(:talks, talks)
         |> assign(:back_to, back_to)
         |> assign(:back_to_title, back_to_title)}
    end
  end
end
