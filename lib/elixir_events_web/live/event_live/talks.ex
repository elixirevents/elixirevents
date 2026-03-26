defmodule ElixirEventsWeb.EventLive.Talks do
  use ElixirEventsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    {:noreply, assign(socket, :page_title, "Talks — #{slug}")}
  end
end
