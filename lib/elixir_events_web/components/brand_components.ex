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
    * `status` - One of :cfp_open, :cfp_closed, :cfp_upcoming, :announced, :confirmed, :completed, :cancelled

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

  def talk_card(assigns) do
    ~H"""
    <div class="group">
      <.link navigate={talk_path(@talk)} class="block relative rounded-xl overflow-hidden mb-4">
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

        <%!-- Duration badge --%>
        <span
          :if={format_duration(@talk.duration)}
          class="absolute bottom-3 right-3 text-xs font-bold px-2 py-0.5 rounded-full bg-base-content/80 text-base-100"
        >
          {format_duration(@talk.duration)}
        </span>

        <%!-- Play overlay (desktop hover only) --%>
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
        navigate={talk_path(@talk)}
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
      <p class="text-xs text-base-content/50 mt-1">
        <.link navigate={"/events/#{@talk.event.slug}"} class="hover:text-primary transition-colors">
          {@talk.event.name}
        </.link>
      </p>
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
      class="flex items-center gap-3 px-4 py-3 rounded-xl border border-base-300 bg-base-200/30 hover:border-primary/40 hover:bg-base-200/60 transition-all min-w-[220px] group"
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
  """
  attr :time_slots, :list, required: true
  attr :limit, :integer, default: nil

  def schedule_list(assigns) do
    slots =
      if assigns.limit, do: Enum.take(assigns.time_slots, assigns.limit), else: assigns.time_slots

    assigns = assign(assigns, :display_slots, slots)

    ~H"""
    <div class="space-y-0.5">
      <div
        :for={slot <- @display_slots}
        class="flex items-start gap-4 py-2.5 px-3 rounded-lg text-sm hover:bg-base-200/40 transition-colors"
      >
        <span class="text-xs text-base-content/50 w-24 shrink-0 pt-0.5 font-medium tabular-nums">
          {Calendar.strftime(slot.start_time, "%H:%M")} – {Calendar.strftime(slot.end_time, "%H:%M")}
        </span>
        <div class="flex-1 min-w-0">
          <div :for={session <- slot.sessions} class="mb-1 last:mb-0">
            <span :if={session.kind in [:break, :social]} class="text-base-content/50">
              {session.title}
            </span>
            <span :if={session.kind not in [:break, :social]} class="font-medium text-base-content">
              {session.title}
            </span>
            <span :if={session.track} class="text-xs text-base-content/40 ml-2">
              ({session.track.name})
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
