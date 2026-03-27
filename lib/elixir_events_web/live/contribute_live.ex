defmodule ElixirEventsWeb.ContributeLive do
  use ElixirEventsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Contribute",
       page_description:
         "Help grow the Elixir & BEAM community directory. Submit events, talks, and speakers via pull requests.",
       page_url: ElixirEventsWeb.SEO.base_url() <> "/contribute"
     )}
  end
end
