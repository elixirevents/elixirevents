defmodule ElixirEventsWeb.TopicLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Topics

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = params["q"]
    topics = Topics.list_topics(with_counts: true, search: search)

    {:noreply,
     socket
     |> assign(:page_title, "Topics")
     |> assign(:page_description, "Explore topics across Elixir & BEAM talks and events.")
     |> assign(:page_url, ElixirEventsWeb.SEO.base_url() <> "/topics")
     |> assign(:topics, topics)
     |> assign(:search, search)}
  end
end
