defmodule ElixirEventsWeb.TalkLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Talks

  @valid_filters ~w(all published scheduled)
  @valid_sorts ~w(newest oldest title)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter = if params["filter"] in @valid_filters, do: params["filter"], else: "all"
    sort = if params["sort"] in @valid_sorts, do: params["sort"], else: "newest"
    page = String.to_integer(params["page"] || "1")
    search = params["q"]

    page_data =
      Talks.paginate_talks(
        filter: filter,
        sort: sort,
        search: search,
        preload: [:event, :recordings, talk_speakers: :profile],
        page: page
      )

    {:noreply,
     socket
     |> assign(:page_title, "Talks")
     |> assign(:talks, page_data.entries)
     |> assign(:page_data, page_data)
     |> assign(:current_filter, filter)
     |> assign(:current_sort, sort)
     |> assign(:search, search)}
  end
end
