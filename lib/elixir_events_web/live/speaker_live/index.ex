defmodule ElixirEventsWeb.SpeakerLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Profiles

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = String.to_integer(params["page"] || "1")
    search = params["q"]

    page_data =
      Profiles.paginate_profiles(
        speakers_only: true,
        with_talk_count: true,
        search: search,
        page: page
      )

    {:noreply,
     socket
     |> assign(:page_title, "Speakers")
     |> assign(:profiles, page_data.entries)
     |> assign(:page_data, page_data)
     |> assign(:search, search)}
  end
end
