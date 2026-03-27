defmodule ElixirEventsWeb.AboutLive do
  use ElixirEventsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "About",
       page_description:
         "ElixirEvents is an open source community directory for Elixir & BEAM conferences, meetups, talks, speakers, and topics.",
       page_url: ElixirEventsWeb.SEO.base_url() <> "/about"
     )}
  end
end
