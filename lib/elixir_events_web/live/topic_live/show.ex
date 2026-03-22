defmodule ElixirEventsWeb.TopicLive.Show do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Topics

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
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

        {:noreply,
         socket
         |> assign(:page_title, topic.name)
         |> assign(:topic, topic)
         |> assign(:talks, talks)}
    end
  end
end
