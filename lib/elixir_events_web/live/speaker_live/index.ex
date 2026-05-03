defmodule ElixirEventsWeb.SpeakerLive.Index do
  use ElixirEventsWeb, :live_view

  alias ElixirEvents.Profiles

  @valid_sorts ~w(name talks)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    sort = if params["sort"] in @valid_sorts, do: params["sort"], else: "name"
    page = String.to_integer(params["page"] || "1")
    search = params["q"]

    page_data =
      Profiles.paginate_profiles(
        speakers_only: true,
        with_talk_count: true,
        order_by: order_by_for(sort),
        search: search,
        page: page
      )

    {:noreply,
     socket
     |> assign(:page_title, "Speakers")
     |> assign(:page_description, "Discover speakers from the Elixir & BEAM community.")
     |> assign(:page_url, ElixirEventsWeb.SEO.base_url() <> "/speakers")
     |> assign(:profiles, page_data.entries)
     |> assign(:page_data, page_data)
     |> assign(:current_sort, sort)
     |> assign(:search, search)}
  end

  defp order_by_for("talks"), do: :talk_count_desc
  defp order_by_for(_), do: :name_asc
end
