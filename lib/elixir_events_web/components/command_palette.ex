defmodule ElixirEventsWeb.CommandPaletteComponent do
  @moduledoc """
  A LiveComponent that renders the global command palette UI and delegates
  navigation events. It integrates with client-side JS for interactive search.
  """
  use ElixirEventsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="command-palette"
      phx-hook="CommandBarHook"
      data-typesense-search-key={@typesense_search_key}
      data-typesense-search-host={@typesense_search_host}
    >
      <div data-palette-overlay class="hidden command-bar-overlay" aria-modal="true" role="dialog">
        <div data-palette-panel class="command-bar-panel">
          <div class="command-bar-search">
            <.icon name="hero-magnifying-glass" class="command-bar-search-icon" />
            <input
              data-palette-input
              type="text"
              placeholder="Search talks, speakers, events, topics..."
              role="combobox"
              aria-expanded="true"
              aria-controls="palette-listbox"
              aria-haspopup="listbox"
              autocomplete="off"
              spellcheck="false"
            />
            <kbd class="command-bar-esc">ESC</kbd>
          </div>

          <div
            data-palette-results
            id="palette-listbox"
            role="listbox"
            aria-label="Search results"
            class="command-bar-results"
          >
          </div>

          <div class="command-bar-footer" data-palette-footer>
            <span class="hidden md:inline">
              <kbd>&uarr;</kbd><kbd>&darr;</kbd> navigate <kbd>&crarr;</kbd> open <kbd>esc</kbd> close
            </span>
          </div>

          <div data-palette-live class="sr-only" aria-live="polite" aria-atomic="true"></div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("navigate", %{"path" => path}, socket) do
    {:noreply, push_navigate(socket, to: path)}
  end
end
