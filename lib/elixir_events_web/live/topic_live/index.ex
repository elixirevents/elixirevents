defmodule ElixirEventsWeb.TopicLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Topics

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    topics = Topics.list_topics(with_counts: true)

    {:noreply,
     socket
     |> assign(:page_title, "Topics")
     |> assign(:topics, topics)}
  end
end
