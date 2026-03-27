defmodule ElixirEventsWeb.BrandComponents do
  @moduledoc """
  ElixirEvents brand components — potion icon, sparkles, status badges,
  and other reusable UI elements specific to the ElixirEvents design system.
  """
  use Phoenix.Component
  import ElixirEventsWeb.Helpers
  import ElixirEventsWeb.CoreComponents, only: [icon: 1]

  @doc """
  Renders the ElixirEvents potion bottle icon.

  ## Attributes
    * `class` - Additional CSS classes (default: "h-8 w-auto")

  ## Examples
      <.potion_icon />
      <.potion_icon class="h-6 w-auto opacity-50" />
  """
  attr :class, :string, default: "h-8 w-auto"
  attr :id, :string, default: "potion"

  def potion_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 28 40" class={@class} fill="none" aria-hidden="true">
      <rect x="9" y="1" width="10" height="5" rx="2" fill="#C4956A" />
      <rect
        x="10.5"
        y="6"
        width="7"
        height="7"
        rx="1"
        fill="#E4DCF0"
        stroke="#8a3897"
        stroke-width="1.2"
      />
      <path
        d="M10.5 13 C4 16 2 22 2 28 C2 36 7 39 14 39 C21 39 26 36 26 28 C26 22 24 16 17.5 13"
        fill="#E4DCF0"
        stroke="#8a3897"
        stroke-width="1.2"
      />
      <path
        d="M4 27 C4 27 4 37 14 37 C24 37 24 27 24 27 C24 23 20 21 14 21 C8 21 4 23 4 27Z"
        fill={"url(##{@id})"}
      />
      <path d="M14 25.5 L14.8 23 L14 20.5 L13.2 23Z" fill="white" opacity="0.85" />
      <path d="M11.5 25.5 L14 24.7 L16.5 25.5 L14 26.3Z" fill="white" opacity="0.85" />
      <circle cx="9" cy="17" r="0.8" fill="white" opacity="0.4" />
      <circle cx="20" cy="15" r="0.6" fill="white" opacity="0.35" />
      <circle cx="19" cy="33" r="0.7" fill="white" opacity="0.5" />
      <defs>
        <linearGradient id={@id} x1="4" y1="21" x2="24" y2="37">
          <stop stop-color="#B464BA" />
          <stop offset="1" stop-color="#8a3897" />
        </linearGradient>
      </defs>
    </svg>
    """
  end

  @doc """
  Renders a 4-pointed sparkle star.

  ## Attributes
    * `class` - CSS classes for size and color (required)

  ## Examples
      <.sparkle class="h-4 w-4 text-secondary" />
      <.sparkle class="h-6 w-6 text-primary/30" />
  """
  attr :class, :string, required: true

  def sparkle(assigns) do
    ~H"""
    <svg viewBox="0 0 16 16" class={@class} fill="currentColor" aria-hidden="true">
      <path d="M8 0 L9.5 5.5 L16 8 L9.5 10.5 L8 16 L6.5 10.5 L0 8 L6.5 5.5Z" />
    </svg>
    """
  end

  @doc """
  Renders a large sparkle (24x24 viewBox, longer rays).

  ## Examples
      <.sparkle_lg class="h-8 w-8 text-primary/10" />
  """
  attr :class, :string, required: true

  def sparkle_lg(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" class={@class} fill="currentColor" aria-hidden="true">
      <path d="M12 0 L13.5 9 L24 12 L13.5 15 L12 24 L10.5 15 L0 12 L10.5 9Z" />
    </svg>
    """
  end

  @doc """
  Renders the GitHub icon.

  ## Examples
      <.github_icon class="h-4 w-4" />
  """
  attr :class, :string, default: "h-4 w-4"

  def github_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 16 16" class={@class} fill="currentColor" aria-hidden="true">
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z" />
    </svg>
    """
  end

  @doc """
  Renders an event status badge.

  ## Attributes
    * `status` - One of :cfp_open, :cfp_closed, :cfp_upcoming, :announced, :confirmed, :ongoing, :completed, :cancelled

  ## Examples
      <.status_badge status={:cfp_open} />
      <.status_badge status={:confirmed} />
  """
  attr :status, :atom, required: true

  def status_badge(assigns) do
    ~H"""
    <span
      :if={@status == :cfp_open}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-success/15 text-success"
    >
      CFP Open
    </span>
    <span
      :if={@status == :cfp_closed}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-warning/15 text-warning"
    >
      CFP Closed
    </span>
    <span
      :if={@status == :cfp_upcoming}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-info/15 text-info"
    >
      CFP Soon
    </span>
    <span
      :if={@status == :announced}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-primary/15 text-primary"
    >
      Announced
    </span>
    <span
      :if={@status == :confirmed}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-info/15 text-info"
    >
      Confirmed
    </span>
    <span
      :if={@status == :ongoing}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-success/15 text-success"
    >
      Happening Now
    </span>
    <span
      :if={@status == :completed}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-base-300/60 text-base-content/55"
    >
      Completed
    </span>
    <span
      :if={@status == :cancelled}
      class="text-xs font-bold px-2.5 py-1 rounded-full bg-error/15 text-error"
    >
      Cancelled
    </span>
    """
  end

  @doc """
  Determines the display status for an event, considering CFP status.
  CFP status takes priority over event status when present.

  ## Examples
      <.status_badge status={event_display_status(event)} />
  """
  def event_display_status(%{cfps: cfps, status: status}) when is_list(cfps) do
    today = Date.utc_today()

    cfp_status =
      Enum.find_value(cfps, fn cfp ->
        cond do
          cfp.close_date && Date.compare(today, cfp.close_date) == :gt -> :cfp_closed
          cfp.open_date && Date.compare(today, cfp.open_date) == :lt -> :cfp_upcoming
          true -> :cfp_open
        end
      end)

    cfp_status || status
  end

  def event_display_status(%{status: status}), do: status

  @doc """
  Renders a chevron-right arrow icon for list rows.

  ## Examples
      <.chevron_right />
  """
  attr :page_data, :map, required: true, doc: "Map with :page, :total_pages, :total_count"
  attr :path, :string, required: true
  attr :params, :map, default: %{}

  def pagination(assigns) do
    ~H"""
    <nav
      :if={@page_data.total_pages > 1}
      class="flex items-center justify-center mt-12"
      aria-label="Pagination"
    >
      <div class="inline-flex items-center gap-1 p-1.5 rounded-2xl bg-base-200/50 border border-base-300/50">
        <.link
          :if={@page_data.page > 1}
          patch={"#{@path}?#{URI.encode_query(Map.merge(@params, %{"page" => @page_data.page - 1}))}"}
          class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-semibold text-base-content/55 hover:text-base-content hover:bg-base-300/50 transition-all duration-200 cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Previous
        </.link>

        <span class="px-4 py-2 text-sm font-medium text-base-content/40 tabular-nums">
          Page {@page_data.page} of {@page_data.total_pages}
        </span>

        <.link
          :if={@page_data.page < @page_data.total_pages}
          patch={"#{@path}?#{URI.encode_query(Map.merge(@params, %{"page" => @page_data.page + 1}))}"}
          class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-semibold text-base-content/55 hover:text-base-content hover:bg-base-300/50 transition-all duration-200 cursor-pointer"
        >
          Next
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </.link>
      </div>
    </nav>
    """
  end

  def chevron_right(assigns) do
    ~H"""
    <svg
      class="w-4 h-4 text-base-content/35 group-hover:text-primary transition-colors hidden sm:block"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
    </svg>
    """
  end

  @doc """
  Renders an inline count badge, e.g. next to a section heading.

  ## Examples
      <h2>Talks <.count_badge count={41} /></h2>
  """
  attr :count, :integer, required: true

  def count_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center justify-center ml-2 px-2.5 py-0.5 rounded-full bg-base-300/60 text-sm font-medium text-base-content/50 tabular-nums">
      {@count}
    </span>
    """
  end

  @doc """
  Renders a talk card with YouTube thumbnail (or gradient fallback),
  kind badge, duration, play overlay, title, speaker, and event name.
  Links to the talk show page.

  ## Attributes
    * `talk` - A Talk struct with :event, :recordings, and :talk_speakers preloaded

  ## Examples
      <.talk_card talk={talk} />
  """
  attr :talk, :map, required: true
  attr :hide_event_name, :boolean, default: false
  attr :back_to, :string, default: nil
  attr :back_to_title, :string, default: nil

  def talk_card(assigns) do
    link_path =
      if assigns.back_to do
        with_back_link(talk_path(assigns.talk), assigns.back_to, assigns.back_to_title)
      else
        talk_path(assigns.talk)
      end

    assigns = assign(assigns, :link_path, link_path)

    ~H"""
    <div class="group">
      <.link navigate={@link_path} class="block relative rounded-xl overflow-hidden mb-4">
        <%= if @talk.kind == :workshop do %>
          <%!-- Workshop card: branded gradient with icon --%>
          <div
            class="aspect-video flex flex-col items-center justify-center gap-3 text-white"
            style={ElixirEvents.Colors.card_style(@talk.title)}
          >
            <div class="w-12 h-12 rounded-full bg-white/15 backdrop-blur-sm flex items-center justify-center">
              <svg class="w-6 h-6 text-white/80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="1.5"
                  d="M4.26 10.147a60.438 60.438 0 0 0-.491 6.347A48.62 48.62 0 0 1 12 20.904a48.62 48.62 0 0 1 8.232-4.41 60.46 60.46 0 0 0-.491-6.347m-15.482 0a50.636 50.636 0 0 0-2.658-.813A59.906 59.906 0 0 1 12 3.493a59.903 59.903 0 0 1 10.399 5.84c-.896.248-1.783.52-2.658.814m-15.482 0A50.717 50.717 0 0 1 12 13.489a50.702 50.702 0 0 1 7.74-3.342M6.75 15a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Zm0 0v-3.675A55.378 55.378 0 0 1 12 8.443m-7.007 11.55A5.981 5.981 0 0 0 6.75 15.75v-1.5"
                />
              </svg>
            </div>
            <span class="text-xs font-semibold text-white/60 uppercase tracking-wider">Training</span>
          </div>
        <% else %>
          <%!-- YouTube thumbnail or gradient fallback --%>
          <div :if={talk_thumbnail_url(@talk)} class="aspect-video">
            <img
              src={talk_thumbnail_url(@talk)}
              alt={@talk.title}
              class="w-full h-full object-cover"
              loading="lazy"
            />
          </div>
          <div
            :if={!talk_thumbnail_url(@talk)}
            class="aspect-video"
            style={ElixirEvents.Colors.card_style(@talk.title)}
          >
          </div>
        <% end %>

        <%!-- Kind badge --%>
        <span class={[
          "absolute top-3 left-3 text-xs font-bold px-2 py-0.5 rounded-full",
          if(@talk.kind == :keynote,
            do: "bg-primary/90 text-primary-content",
            else:
              if(@talk.kind == :workshop,
                do: "bg-accent/90 text-accent-content",
                else: "bg-base-content/70 text-base-100"
              )
          )
        ]}>
          {talk_kind_label(@talk.kind)}
        </span>

        <%!-- Duration badge (skip for workshops — "8h" isn't useful) --%>
        <span
          :if={format_duration(@talk.duration) && @talk.kind != :workshop}
          class="absolute bottom-3 right-3 text-xs font-bold px-2 py-0.5 rounded-full bg-base-content/80 text-base-100"
        >
          {format_duration(@talk.duration)}
        </span>

        <%!-- Play overlay (desktop hover only, not for workshops) --%>
        <div
          :if={has_recording?(@talk)}
          class="absolute inset-0 hidden items-center justify-center lg:group-hover:flex bg-black/30"
        >
          <div class="w-12 h-12 rounded-full bg-white/95 flex items-center justify-center shadow-lg shadow-black/20">
            <.icon name="hero-play-solid" class="size-5 text-base-300 ml-0.5" />
          </div>
        </div>
      </.link>

      <.link
        navigate={@link_path}
        class="font-display font-bold text-base-content hover:text-primary transition-colors line-clamp-2 block"
      >
        {@talk.title}
      </.link>
      <p class="text-sm text-base-content/55 mt-1">
        <span :for={{ts, idx} <- Enum.with_index(@talk.talk_speakers)}>
          <span :if={idx > 0}>, </span>
          <.link
            navigate={"/profiles/#{ts.profile.handle}"}
            class="hover:text-primary transition-colors"
          >
            {ts.profile.name}
          </.link>
        </span>
      </p>
      <p :if={!@hide_event_name} class="text-xs text-base-content/50 mt-1">
        <.link navigate={"/events/#{@talk.event.slug}"} class="hover:text-primary transition-colors">
          {@talk.event.name}
        </.link>
      </p>
    </div>
    """
  end

  @doc """
  Renders a contextual back link. Uses `back_to`/`back_to_title` from assigns
  (parsed from query params) if available, otherwise falls back to a default.

  ## Attributes
    * `back_to` - The back link path (from query param), or nil
    * `back_to_title` - The back link label (from query param), or nil
    * `default_path` - Fallback navigation path
    * `default_title` - Fallback link text
  """
  attr :back_to, :string, default: nil
  attr :back_to_title, :string, default: nil
  attr :default_path, :string, required: true
  attr :default_title, :string, required: true

  def back_link(assigns) do
    ~H"""
    <div class="mb-8">
      <.link
        navigate={@back_to || @default_path}
        class="text-sm text-base-content/55 hover:text-primary transition-colors inline-flex items-center gap-1.5"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        {@back_to_title || @default_title}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a compact hero banner for sub-pages with breadcrumb navigation.

  ## Attributes
    * `event` - The event map with `:slug` and `:name`
    * `title` - The page title shown in the hero
  """
  attr :event, :map, required: true
  attr :title, :string, required: true

  def compact_hero(assigns) do
    ~H"""
    <div class="relative rounded-2xl overflow-hidden mb-8">
      <div class="absolute inset-0" style={card_style(@event)}></div>
      <div class="absolute inset-0 opacity-[0.06]" style={card_pattern(@event.name)}></div>
      <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
      <div class="relative px-6 sm:px-10 py-6 sm:py-8 text-white">
        <nav class="text-xs text-white/60 mb-3 flex items-center gap-1.5">
          <.link navigate="/events" class="hover:text-white/80 transition-colors">Events</.link>
          <span>/</span>
          <.link navigate={"/events/#{@event.slug}"} class="hover:text-white/80 transition-colors">
            {@event.name}
          </.link>
          <span>/</span>
          <span class="text-white/90">{@title}</span>
        </nav>
        <h1 class="font-display text-2xl sm:text-3xl font-bold">{@title}</h1>
      </div>
    </div>
    """
  end

  @doc """
  Renders sticky anchor navigation with SectionObserverHook.

  ## Attributes
    * `sections` - List of maps with `:id`, `:label`, and optional `:count`
  """
  attr :sections, :list, required: true

  def section_nav(assigns) do
    ~H"""
    <nav
      id="section-nav"
      phx-hook="SectionObserverHook"
      class="sticky top-[52px] z-40 bg-base-100/92 backdrop-blur-md border-b border-base-300/50 -mx-4 sm:-mx-6 lg:-mx-0 px-4 sm:px-6 lg:px-0 overflow-x-auto scrollbar-none"
    >
      <div class="flex gap-0 min-w-max">
        <a
          :for={section <- @sections}
          href={"##{section.id}"}
          data-section-id={section.id}
          class="px-3 sm:px-4 py-3 text-xs sm:text-sm font-medium text-base-content/50 border-b-2 border-transparent hover:text-base-content transition-colors whitespace-nowrap [&.active]:text-primary [&.active]:border-primary"
        >
          {section.label}
          <span :if={section[:count]} class="text-base-content/30 ml-0.5 text-xs">
            ({section.count})
          </span>
        </a>
      </div>
    </nav>
    """
  end

  @doc """
  Renders a horizontal card for keynote speaker preview.

  ## Attributes
    * `speaker` - A speaker map with `:handle`, `:name`, and optional `:headline`
    * `talk_title` - Optional talk title
  """
  attr :speaker, :map, required: true
  attr :talk_title, :string, default: nil

  def keynote_card(assigns) do
    ~H"""
    <.link
      navigate={"/profiles/#{@speaker.handle}"}
      class="flex items-center gap-3 px-4 py-3 rounded-xl border border-base-300 bg-base-200/30 hover:border-primary/40 hover:bg-base-200/60 transition-all min-w-[260px] group"
    >
      <div
        class="w-12 h-12 rounded-full shrink-0 flex items-center justify-center text-white font-bold text-sm"
        style={avatar_style(@speaker.name)}
      >
        {initials(@speaker.name)}
      </div>
      <div class="min-w-0">
        <div class="font-semibold text-sm text-base-content group-hover:text-primary transition-colors truncate">
          {@speaker.name}
        </div>
        <div :if={@speaker.headline} class="text-xs text-base-content/50 truncate">
          {@speaker.headline}
        </div>
      </div>
    </.link>
    """
  end

  @doc """
  Renders a grid card for speakers sub-page.

  ## Attributes
    * `speaker` - A speaker map with `:handle`, `:name`, and optional `:headline`
    * `talk_count` - Number of talks by this speaker
    * `is_keynote` - Whether the speaker is a keynote speaker
  """
  attr :speaker, :map, required: true
  attr :talk_count, :integer, default: 0
  attr :is_keynote, :boolean, default: false

  def speaker_card(assigns) do
    ~H"""
    <.link
      navigate={"/profiles/#{@speaker.handle}"}
      class="flex items-center gap-3 p-4 rounded-xl border border-base-300 hover:border-primary/40 hover:bg-base-200/30 transition-all group"
    >
      <div
        class="w-14 h-14 rounded-full shrink-0 flex items-center justify-center text-white font-bold"
        style={avatar_style(@speaker.name)}
      >
        {initials(@speaker.name)}
      </div>
      <div class="min-w-0 flex-1">
        <div class="font-semibold text-sm group-hover:text-primary transition-colors">
          {@speaker.name}
        </div>
        <div :if={@speaker.headline} class="text-xs text-base-content/50 truncate mt-0.5">
          {@speaker.headline}
        </div>
        <div class="flex items-center gap-2 mt-1">
          <span
            :if={@is_keynote}
            class="text-[0.65rem] font-semibold px-1.5 py-0.5 rounded-full bg-secondary/15 text-secondary"
          >
            Keynote
          </span>
          <span :if={@talk_count > 0} class="text-[0.65rem] text-base-content/40">
            {if @talk_count == 1, do: "1 talk", else: "#{@talk_count} talks"}
          </span>
        </div>
      </div>
    </.link>
    """
  end

  @doc """
  Renders a venue card with map embed, address, and direction links.

  ## Attributes
    * `venue` - A venue map with `:name`, `:street`, `:city`, `:region`, `:postal_code`, `:country`,
      optional `:description`, and optional `:latitude`/`:longitude`
  """
  attr :venue, :map, required: true

  def venue_card(assigns) do
    ~H"""
    <div class="rounded-xl overflow-hidden border border-base-300">
      <div
        :if={has_coordinates?(@venue)}
        id={"venue-map-#{@venue.slug}"}
        phx-hook="VenueMapHook"
        phx-update="ignore"
        data-lat={@venue.latitude}
        data-lng={@venue.longitude}
        data-name={@venue.name}
        class="venue-map-container w-full h-[320px]"
      >
      </div>
      <div class="p-5">
        <h3 class="font-display font-bold text-lg">{@venue.name}</h3>
        <p class="text-sm text-base-content/55 mt-1 leading-relaxed">
          <span :if={@venue.street}>{@venue.street}<br /></span>
          {venue_address_line(@venue)}
        </p>
        <p :if={@venue.description} class="text-sm text-base-content/50 mt-3 leading-relaxed">
          {@venue.description}
        </p>
        <div :if={has_coordinates?(@venue)} class="flex flex-wrap gap-2 mt-4">
          <.direction_link href={google_maps_url(@venue)} label="Google Maps" />
          <.direction_link href={apple_maps_url(@venue)} label="Apple Maps" />
          <.direction_link href={openstreetmap_url(@venue)} label="OpenStreetMap" />
        </div>
      </div>
    </div>
    """
  end

  defp direction_link(assigns) do
    ~H"""
    <a
      href={@href}
      target="_blank"
      rel="noopener"
      class="inline-flex items-center gap-1 text-xs px-2.5 py-1.5 rounded-md border border-base-300 text-base-content/60 hover:border-primary/40 hover:text-primary transition-all"
    >
      <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
        />
      </svg>
      {@label}
    </a>
    """
  end

  defp venue_address_line(venue) do
    [venue.city, venue.region, venue.postal_code, venue.country]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  @doc """
  Renders a tiered sponsor display with size hierarchy.

  ## Attributes
    * `tiers` - List of maps with `:name`, `:level`, and `:sponsors`
  """
  attr :tiers, :list, required: true

  def sponsor_display(assigns) do
    ~H"""
    <div class="space-y-10">
      <div :for={tier <- @tiers} class="text-center">
        <div class="text-xs text-base-content/40 uppercase tracking-widest font-semibold mb-5">
          {tier.name}
        </div>
        <div class="flex flex-wrap items-center justify-center gap-6">
          <a
            :for={sponsor <- tier.sponsors}
            href={sponsor.organization.website}
            target="_blank"
            rel="noopener"
            class={[
              "flex items-center justify-center rounded-xl transition-all hover:scale-105 bg-white/90",
              sponsor_pad_classes(tier.level)
            ]}
            title={sponsor.organization.name}
          >
            <img
              :if={sponsor.organization.logo_url}
              src={sponsor.organization.logo_url}
              alt={sponsor.organization.name}
              class={["object-contain", sponsor_logo_classes(tier.level)]}
              loading="lazy"
            />
            <span
              :if={!sponsor.organization.logo_url}
              class="text-base-content/60 font-semibold text-sm"
            >
              {sponsor.organization.name}
            </span>
          </a>
        </div>
      </div>
    </div>
    """
  end

  defp sponsor_pad_classes(1), do: "px-8 py-5"
  defp sponsor_pad_classes(2), do: "px-6 py-4"
  defp sponsor_pad_classes(_), do: "px-5 py-3"

  defp sponsor_logo_classes(1), do: "h-14 max-w-[200px]"
  defp sponsor_logo_classes(2), do: "h-11 max-w-[170px]"
  defp sponsor_logo_classes(_), do: "h-9 max-w-[140px]"

  @doc """
  Renders pill-style day switcher tabs.

  ## Attributes
    * `days` - List of day maps with `:id`, optional `:name`, and `:date`
    * `selected_day_id` - The currently selected day ID
  """
  attr :days, :list, required: true
  attr :selected_day_id, :integer, required: true

  def day_tabs(assigns) do
    ~H"""
    <div class="flex gap-2 flex-wrap">
      <button
        :for={day <- @days}
        phx-click="select-day"
        phx-value-day-id={day.id}
        class={[
          "px-3.5 py-1.5 rounded-full text-sm font-medium border transition-all",
          if(day.id == @selected_day_id,
            do: "bg-primary border-primary text-white",
            else:
              "border-base-300 text-base-content/60 hover:border-primary/40 hover:text-base-content"
          )
        ]}
      >
        {day.name || Calendar.strftime(day.date, "%a, %b %d")}
      </button>
    </div>
    """
  end

  @doc """
  Renders a chronological list for schedule preview and mobile.

  ## Attributes
    * `time_slots` - List of time slot maps with `:start_time`, `:end_time`, and `:sessions`
    * `limit` - Optional limit on number of slots to display
    * `event` - The event (for building talk links). Optional for backward compatibility.
    * `back_path` - Path to use for back link on talk pages. Optional.
  """
  attr :time_slots, :list, required: true
  attr :limit, :integer, default: nil
  attr :event, :map, default: nil
  attr :back_path, :string, default: nil
  attr :show_tracks?, :boolean, default: false

  def schedule_list(assigns) do
    slots =
      if assigns.limit, do: Enum.take(assigns.time_slots, assigns.limit), else: assigns.time_slots

    assigns = assign(assigns, :display_slots, slots)

    ~H"""
    <div class="space-y-1">
      <%= for slot <- @display_slots do %>
        <% is_break? = Enum.any?(slot.sessions, &(&1.kind in [:break, :social])) %>

        <%= if is_break? do %>
          <% break_session = Enum.find(slot.sessions, &(&1.kind in [:break, :social])) %>
          <div class="flex items-center gap-3 py-2.5 px-1">
            <span class="text-[11px] text-base-content/30 w-20 shrink-0 font-medium tabular-nums text-right">
              {Calendar.strftime(slot.start_time, "%H:%M")}
            </span>
            <div class="flex-1 flex items-center gap-3">
              <div class="flex-1 border-t border-dashed border-base-content/10"></div>
              <span class="text-xs text-base-content/30 font-medium">{break_session.title}</span>
              <div class="flex-1 border-t border-dashed border-base-content/10"></div>
            </div>
          </div>
        <% else %>
          <div class="flex gap-3 py-1">
            <div class="w-20 shrink-0 text-right pt-3 px-1">
              <div class="text-xs text-base-content/45 font-medium tabular-nums">
                {Calendar.strftime(slot.start_time, "%H:%M")}
              </div>
              <div class="text-[10px] text-base-content/25 tabular-nums">
                {Calendar.strftime(slot.end_time, "%H:%M")}
              </div>
            </div>
            <div class="flex-1 min-w-0 space-y-1.5">
              <.schedule_session_card
                :for={session <- slot.sessions}
                :if={session.kind not in [:break, :social]}
                session={session}
                event={@event}
                back_path={@back_path}
                show_track?={@show_tracks?}
              />
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a single schedule session as a card with title, speakers, and kind badge.
  Links to the talk detail page when the session has an associated talk.
  """
  attr :session, :map, required: true
  attr :event, :map, default: nil
  attr :back_path, :string, default: nil
  attr :show_track?, :boolean, default: false

  def schedule_session_card(assigns) do
    talk = if assigns.session.talk_id, do: assigns.session.talk, else: nil
    speakers = if talk, do: talk.talk_speakers |> Enum.sort_by(& &1.position), else: []

    talk_path =
      if talk && assigns.event do
        base = "/talks/#{assigns.event.slug}/#{talk.slug}"

        if assigns.back_path do
          with_back_link(base, assigns.back_path, "Schedule")
        else
          base
        end
      end

    assigns =
      assigns
      |> assign(:talk, talk)
      |> assign(:speakers, speakers)
      |> assign(:talk_path, talk_path)

    ~H"""
    <.link
      :if={@talk_path}
      navigate={@talk_path}
      class="group block p-4 rounded-xl border border-base-content/[0.06] bg-base-200/20 hover:bg-base-200/40 hover:border-primary/20 transition-all"
    >
      <.session_card_inner session={@session} speakers={@speakers} show_track?={@show_track?} />
    </.link>
    <div
      :if={!@talk_path}
      class="p-4 rounded-xl border border-base-content/[0.06] bg-base-200/20"
    >
      <.session_card_inner session={@session} speakers={@speakers} show_track?={@show_track?} />
    </div>
    """
  end

  attr :session, :map, required: true
  attr :speakers, :list, default: []
  attr :show_track?, :boolean, default: false

  defp session_card_inner(assigns) do
    ~H"""
    <div class="flex items-start justify-between gap-3">
      <div class="flex-1 min-w-0">
        <%!-- Badges row --%>
        <div class="flex flex-wrap items-center gap-1.5 mb-1.5">
          <span
            :if={@session.kind == :keynote}
            class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-primary/15 text-primary uppercase tracking-wide"
          >
            Keynote
          </span>
          <span
            :if={@session.kind == :lightning_talk}
            class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-accent/15 text-accent uppercase tracking-wide"
          >
            Lightning
          </span>
          <span
            :if={@show_track? && @session.track}
            class="text-[10px] font-medium px-2 py-0.5 rounded-full bg-base-300/60 text-base-content/45"
          >
            {@session.track.name}
          </span>
        </div>

        <%!-- Title --%>
        <div class={[
          "font-medium text-sm leading-snug",
          if(@session.kind == :keynote,
            do: "text-base-content font-display font-bold",
            else: "text-base-content group-hover:text-primary transition-colors"
          )
        ]}>
          {@session.title}
        </div>

        <%!-- Speakers --%>
        <div :if={@speakers != []} class="flex items-center gap-2 mt-2">
          <div class="flex -space-x-1.5">
            <div
              :for={ts <- Enum.take(@speakers, 4)}
              class="w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-display font-bold ring-2 ring-base-100 shrink-0"
              style={avatar_style(ts.profile.name)}
            >
              {initials(ts.profile.name)}
            </div>
          </div>
          <span class="text-xs text-base-content/50 truncate">
            {@speakers |> Enum.map_join(", ", & &1.profile.name)}
          </span>
        </div>
      </div>

      <%!-- Chevron for linked sessions --%>
      <svg
        :if={@session.talk_id}
        class="w-4 h-4 text-base-content/20 group-hover:text-primary shrink-0 mt-1 transition-colors"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
      </svg>
    </div>
    """
  end
end
