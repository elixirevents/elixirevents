import Typesense from "typesense"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const prefersReducedMotion = () =>
  window.matchMedia("(prefers-reduced-motion: reduce)").matches

function escapeHtml(str) {
  if (!str) return ""
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
}

// Unix epoch seconds for "now" — used to filter upcoming events
function nowTimestamp() {
  return Math.floor(Date.now() / 1000)
}

// Gregorian days since epoch 0000-01-01 (matches Elixir's Date.to_gregorian_days)
// Typesense stores start_date as gregorian days, not unix seconds.
function todayGregorianDays() {
  // JS Date epoch is 1970-01-01 which is gregorian day 719528
  const GREGORIAN_EPOCH_OFFSET = 719528
  const msSinceEpoch = Date.now()
  const daysSinceEpoch = Math.floor(msSinceEpoch / 86400000)
  return GREGORIAN_EPOCH_OFFSET + daysSinceEpoch
}

// ---------------------------------------------------------------------------
// Render helpers
// ---------------------------------------------------------------------------

function renderTopicPills(hits, query) {
  if (!hits || hits.length === 0) return ""

  const pills = hits
    .map((hit, i) => {
      const doc = hit.document
      const path = `/topics/${escapeHtml(doc.slug)}`
      return `
        <a
          class="command-bar-pill command-bar-item"
          data-path="${path}"
          data-index="${i}"
          href="${path}"
          role="option"
          aria-selected="false"
        >${escapeHtml(doc.name)}</a>`
    })
    .join("")

  const seeAll =
    hits.length >= 5
      ? `<a class="command-bar-see-all" data-see-all="/topics?q=${encodeURIComponent(query)}" href="/topics?q=${encodeURIComponent(query)}">See all topics &rarr;</a>`
      : ""

  return `
    <div class="command-bar-topics-row">
      <span class="command-bar-section-label">Topics</span>
      <div class="command-bar-pills">${pills}</div>
      ${seeAll}
    </div>`
}

function renderTalkItem(doc, index) {
  const path = `/talks/${escapeHtml(doc.event_slug)}/${escapeHtml(doc.slug)}`
  const speakers = Array.isArray(doc.speaker_names)
    ? doc.speaker_names.join(", ")
    : ""
  const meta = [doc.event_name, speakers].filter(Boolean).join(" · ")

  const thumb = doc.thumbnail_url
    ? `<img src="${escapeHtml(doc.thumbnail_url)}" alt="" class="command-bar-talk-thumb" loading="lazy" />`
    : `<div class="command-bar-talk-thumb" aria-hidden="true"></div>`

  return `
    <a
      class="command-bar-item"
      data-path="${path}"
      data-index="${index}"
      data-col="main"
      href="${path}"
      role="option"
      aria-selected="false"
    >
      ${thumb}
      <div class="command-bar-item-text">
        <span class="command-bar-item-title">${escapeHtml(doc.title)}</span>
        ${meta ? `<span class="command-bar-item-meta">${escapeHtml(meta)}</span>` : ""}
      </div>
    </a>`
}

function avatarStyle(name) {
  // Match Elixir Colors.avatar_style — deterministic hue from name
  let hash = 0
  for (let i = 0; i < name.length; i++) hash = ((hash << 5) - hash + name.charCodeAt(i)) | 0
  const hue = ((hash % 360) + 360) % 360
  const hue2 = (hue + 20) % 360
  return `background: linear-gradient(135deg, oklch(85% 0.1 ${hue}), oklch(78% 0.14 ${hue2})); color: oklch(35% 0.12 ${hue});`
}

function initials(name) {
  if (!name) return "?"
  const parts = name.trim().split(/\s+/)
  if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
  return parts[0][0].toUpperCase()
}

function renderSpeakerItem(doc, index) {
  const path = `/profiles/${escapeHtml(doc.handle)}`
  const style = avatarStyle(doc.name || "")
  const avatarContent = doc.avatar_url
    ? `<img src="${escapeHtml(doc.avatar_url)}" alt="" class="command-bar-avatar-img" />`
    : `<span class="command-bar-avatar-initials" aria-hidden="true">${initials(doc.name)}</span>`

  return `
    <a
      class="command-bar-item"
      data-path="${path}"
      data-index="${index}"
      data-col="side"
      href="${path}"
      role="option"
      aria-selected="false"
    >
      <div class="command-bar-avatar" style="${style}" aria-hidden="true">${avatarContent}</div>
      <div class="command-bar-item-text">
        <span class="command-bar-item-title">${escapeHtml(doc.name)}</span>
      </div>
    </a>`
}

function eventColorStyle(doc) {
  // Generate a deterministic hue from the event name (matches Elixir's Colors module)
  if (doc.color) return `background: ${escapeHtml(doc.color)};`
  // Fallback: hash the name to a hue
  let hash = 0
  const name = doc.name || ""
  for (let i = 0; i < name.length; i++) hash = ((hash << 5) - hash + name.charCodeAt(i)) | 0
  const hue = ((hash % 360) + 360) % 360
  return `background: linear-gradient(135deg, oklch(40% 0.16 ${hue}), oklch(50% 0.19 ${(hue + 40) % 360}));`
}

function renderEventItem(doc, index) {
  const path = `/events/${escapeHtml(doc.slug)}`
  const meta = [doc.kind, doc.location].filter(Boolean).join(" · ")
  const colorStyle = eventColorStyle(doc)

  return `
    <a
      class="command-bar-item"
      data-path="${path}"
      data-index="${index}"
      data-col="side"
      href="${path}"
      role="option"
      aria-selected="false"
    >
      <div class="command-bar-event-chip" style="${colorStyle}" aria-hidden="true"></div>
      <div class="command-bar-item-text">
        <span class="command-bar-item-title">${escapeHtml(doc.name)}</span>
        ${meta ? `<span class="command-bar-item-meta">${escapeHtml(meta)}</span>` : ""}
      </div>
    </a>`
}

function renderSeriesItem(doc, index) {
  const path = `/series/${escapeHtml(doc.slug)}`
  const meta = [doc.kind, doc.frequency].filter(Boolean).join(" · ")

  return `
    <a
      class="command-bar-item"
      data-path="${path}"
      data-index="${index}"
      href="${path}"
      role="option"
      aria-selected="false"
    >
      <div class="command-bar-event-icon" aria-hidden="true"></div>
      <div class="command-bar-item-text">
        <span class="command-bar-item-title">${escapeHtml(doc.name)}</span>
        ${meta ? `<span class="command-bar-item-meta">${escapeHtml(meta)}</span>` : ""}
      </div>
    </a>`
}

// Build the hybrid two-column layout for a query search
// Returns { html, itemCount }
function buildSearchResults(results, query) {
  // results.results order matches the searches array:
  // 0: topics, 1: talks, 2: profiles, 3: events, 4: event_series
  const [topicsRes, talksRes, profilesRes, eventsRes, seriesRes] = results.results

  const topicHits = (topicsRes && topicsRes.hits) || []
  const talkHits = (talksRes && talksRes.hits) || []
  const profileHits = (profilesRes && profilesRes.hits) || []
  const eventHits = (eventsRes && eventsRes.hits) || []
  const seriesHits = (seriesRes && seriesRes.hits) || []

  const totalHits =
    topicHits.length +
    talkHits.length +
    profileHits.length +
    eventHits.length +
    seriesHits.length

  if (totalHits === 0) {
    return {
      html: `<div class="command-bar-empty" role="status">No results for <strong>${escapeHtml(query)}</strong></div>`,
      itemCount: 0,
    }
  }

  // Assign sequential data-index values across all items for keyboard nav
  let idx = 0

  // Topics section (pills, spans full width)
  const topicsHtml = renderTopicPills(topicHits, query)
  if (topicHits.length > 0) idx += topicHits.length

  // Talks (main col, 60%)
  let talksHtml = ""
  if (talkHits.length > 0) {
    const items = talkHits.map((h) => renderTalkItem(h.document, idx++)).join("")
    const seeAll =
      talkHits.length >= 10
        ? `<div class="command-bar-see-all-row"><a class="command-bar-see-all" data-see-all="/talks?q=${encodeURIComponent(query)}" href="/talks?q=${encodeURIComponent(query)}">See all talks &rarr;</a></div>`
        : ""
    talksHtml = `
      <div>
        <div class="command-bar-section-header">Talks</div>
        ${items}
        ${seeAll}
      </div>`
  }

  // Speakers section (side col)
  let speakersHtml = ""
  if (profileHits.length > 0) {
    const items = profileHits
      .map((h) => renderSpeakerItem(h.document, idx++))
      .join("")
    const seeAll =
      profileHits.length >= 5
        ? `<div class="command-bar-see-all-row"><a class="command-bar-see-all" data-see-all="/speakers?q=${encodeURIComponent(query)}" href="/speakers?q=${encodeURIComponent(query)}">See all speakers &rarr;</a></div>`
        : ""
    speakersHtml = `
      <div>
        <div class="command-bar-section-header">Speakers</div>
        ${items}
        ${seeAll}
      </div>`
  }

  // Events section (side col)
  let eventsHtml = ""
  if (eventHits.length > 0) {
    const items = eventHits.map((h) => renderEventItem(h.document, idx++)).join("")
    const seeAll =
      eventHits.length >= 5
        ? `<div class="command-bar-see-all-row"><a class="command-bar-see-all" data-see-all="/events?q=${encodeURIComponent(query)}" href="/events?q=${encodeURIComponent(query)}">See all events &rarr;</a></div>`
        : ""
    eventsHtml = `
      <div>
        <div class="command-bar-section-header">Events</div>
        ${items}
        ${seeAll}
      </div>`
  }

  // Series section (side col)
  let seriesHtml = ""
  if (seriesHits.length > 0) {
    const items = seriesHits
      .map((h) => renderSeriesItem(h.document, idx++))
      .join("")
    seriesHtml = `
      <div>
        <div class="command-bar-section-header">Event Series</div>
        ${items}
      </div>`
  }

  const mainCol = talksHtml
    ? `<div class="command-bar-main-col">${talksHtml}</div>`
    : ""

  const sideContent = [speakersHtml, eventsHtml, seriesHtml]
    .filter(Boolean)
    .join("")
  const sideCol = sideContent
    ? `<div class="command-bar-side-col">${sideContent}</div>`
    : ""

  // If only one side or neither has talks, fall back to single column
  let columnsHtml
  if (mainCol && sideCol) {
    columnsHtml = `<div class="command-bar-columns">${mainCol}${sideCol}</div>`
  } else if (mainCol) {
    columnsHtml = `<div class="command-bar-columns command-bar-columns--single">${mainCol}</div>`
  } else if (sideCol) {
    columnsHtml = `<div class="command-bar-columns command-bar-columns--single">${sideCol}</div>`
  } else {
    columnsHtml = ""
  }

  return {
    html: topicsHtml + columnsHtml,
    itemCount: idx,
  }
}

// Build empty-state layout from three targeted queries
// results.results order: 0: recent talks, 1: upcoming events, 2: top speakers
function buildEmptyState(results) {
  const [talksRes, eventsRes, speakersRes] = results.results

  const talkHits = (talksRes && talksRes.hits) || []
  const eventHits = (eventsRes && eventsRes.hits) || []
  const speakerHits = (speakersRes && speakersRes.hits) || []

  let idx = 0

  let talksHtml = ""
  if (talkHits.length > 0) {
    const items = talkHits.map((h) => renderTalkItem(h.document, idx++)).join("")
    talksHtml = `
      <div>
        <div class="command-bar-section-header">Recent Talks</div>
        ${items}
      </div>`
  }

  let eventsHtml = ""
  if (eventHits.length > 0) {
    const items = eventHits
      .map((h) => renderEventItem(h.document, idx++))
      .join("")
    eventsHtml = `
      <div>
        <div class="command-bar-section-header">Upcoming Events</div>
        ${items}
      </div>`
  }

  let speakersHtml = ""
  if (speakerHits.length > 0) {
    const items = speakerHits
      .map((h) => renderSpeakerItem(h.document, idx++))
      .join("")
    speakersHtml = `
      <div>
        <div class="command-bar-section-header">Speakers</div>
        ${items}
      </div>`
  }

  if (idx === 0) {
    return { html: "", itemCount: 0 }
  }

  // Two-column: talks left (main), events + speakers right (side)
  const mainCol = talksHtml
    ? `<div class="command-bar-main-col">${talksHtml}</div>`
    : ""
  const sideContent = [eventsHtml, speakersHtml].filter(Boolean).join("")
  const sideCol = sideContent
    ? `<div class="command-bar-side-col">${sideContent}</div>`
    : ""

  let html
  if (mainCol && sideCol) {
    html = `<div class="command-bar-columns">${mainCol}${sideCol}</div>`
  } else if (mainCol || sideCol) {
    html = `<div class="command-bar-columns command-bar-columns--single">${mainCol}${sideCol}</div>`
  } else {
    html = ""
  }

  return { html, itemCount: idx }
}

// ---------------------------------------------------------------------------
// Hook
// ---------------------------------------------------------------------------

const CommandBarHook = {
  mounted() {
    this._isOpen = false
    this._activeIndex = -1
    this._itemCount = 0
    this._savedFocus = null
    this._debounceTimer = null
    this._client = null

    // Elements (all accessed via data attributes so they survive patch)
    this._overlay = this.el.querySelector("[data-palette-overlay]")
    this._panel = this.el.querySelector("[data-palette-panel]")
    this._input = this.el.querySelector("[data-palette-input]")
    this._results = this.el.querySelector("[data-palette-results]")
    this._live = this.el.querySelector("[data-palette-live]")

    // Build Typesense client from data attributes
    const searchKey = this.el.dataset.typesenseSearchKey
    const searchHostRaw = this.el.dataset.typesenseSearchHost

    if (searchKey && searchHostRaw) {
      try {
        const url = new URL(searchHostRaw)
        this._client = new Typesense.Client({
          nodes: [{
            host: url.hostname,
            port: url.port || (url.protocol === "https:" ? "443" : "8108"),
            protocol: url.protocol.replace(":", ""),
          }],
          apiKey: searchKey,
          connectionTimeoutSeconds: 2,
        })
      } catch (e) {
        console.error("[CommandBarHook] Failed to init Typesense client:", e)
      }
    }

    // Event listeners
    this._onToggle = () => this._toggle()
    this._onKeydown = (e) => this._handleKeydown(e)
    this._onOverlayClick = (e) => {
      if (e.target === this._overlay) this._close()
    }
    this._onInputInput = () => this._onInput()
    this._onResultClick = (e) => this._handleResultClick(e)

    window.addEventListener("toggle-palette", this._onToggle)
    document.addEventListener("keydown", this._onKeydown)
    this._overlay && this._overlay.addEventListener("click", this._onOverlayClick)
    this._input && this._input.addEventListener("input", this._onInputInput)
    this._results && this._results.addEventListener("click", this._onResultClick)
  },

  destroyed() {
    window.removeEventListener("toggle-palette", this._onToggle)
    document.removeEventListener("keydown", this._onKeydown)
    this._overlay && this._overlay.removeEventListener("click", this._onOverlayClick)
    this._input && this._input.removeEventListener("input", this._onInputInput)
    this._results && this._results.removeEventListener("click", this._onResultClick)
    clearTimeout(this._debounceTimer)
  },

  // -------------------------------------------------------------------------
  // Open / close
  // -------------------------------------------------------------------------

  _open() {
    if (this._isOpen) return
    this._isOpen = true
    this._savedFocus = document.activeElement

    this._overlay && this._overlay.classList.remove("hidden")

    if (!prefersReducedMotion()) {
      // Trigger CSS enter transition by removing the "pre-enter" state
      // Classes are controlled purely by CSS; we just ensure hidden is gone.
    }

    this._input && this._input.focus()
    this._input && (this._input.value = "")

    // Fetch empty state
    this._fetchEmptyState()

    // Set ARIA
    this._input && this._input.setAttribute("aria-expanded", "true")
    document.body.style.overflow = "hidden"
  },

  _close() {
    if (!this._isOpen) return
    this._isOpen = false

    this._overlay && this._overlay.classList.add("hidden")
    this._results && (this._results.innerHTML = "")
    this._live && (this._live.textContent = "")
    this._activeIndex = -1
    this._itemCount = 0

    // Restore ARIA
    this._input && this._input.setAttribute("aria-expanded", "false")
    document.body.style.overflow = ""

    // Restore focus
    if (this._savedFocus && typeof this._savedFocus.focus === "function") {
      this._savedFocus.focus()
    }
    this._savedFocus = null
    clearTimeout(this._debounceTimer)
  },

  _toggle() {
    this._isOpen ? this._close() : this._open()
  },

  // -------------------------------------------------------------------------
  // Input handling with debounce
  // -------------------------------------------------------------------------

  _onInput() {
    clearTimeout(this._debounceTimer)
    const query = this._input ? this._input.value.trim() : ""

    if (!query) {
      this._fetchEmptyState()
      return
    }

    this._debounceTimer = setTimeout(() => {
      this._search(query)
    }, 250)
  },

  // -------------------------------------------------------------------------
  // Typesense queries
  // -------------------------------------------------------------------------

  async _search(query) {
    if (!this._client) {
      this._renderResults(
        `<div class="command-bar-empty">Search is temporarily unavailable.</div>`,
        0
      )
      return
    }

    try {
      const results = await this._client.multiSearch.perform({
        searches: [
          {
            collection: "topics",
            q: query,
            query_by: "name,description",
            per_page: 5,
          },
          {
            collection: "talks",
            q: query,
            query_by: "title,abstract,speaker_names",
            per_page: 10,
          },
          {
            collection: "profiles",
            q: query,
            query_by: "name,handle,headline",
            per_page: 8,
          },
          {
            collection: "events",
            q: query,
            query_by: "name,description,location",
            per_page: 8,
          },
          {
            collection: "event_series",
            q: query,
            query_by: "name,description",
            per_page: 5,
          },
        ],
      })

      const { html, itemCount } = buildSearchResults(results, query)
      this._itemCount = itemCount
      this._activeIndex = -1
      this._renderResults(html, itemCount)
    } catch (err) {
      console.error("[CommandBarHook] Search error:", err)
      this._renderResults(
        `<div class="command-bar-empty">Search error — please try again.</div>`,
        0
      )
    }
  },

  async _fetchEmptyState() {
    if (!this._client) return

    const today = todayGregorianDays()

    try {
      const results = await this._client.multiSearch.perform({
        searches: [
          // Recent talks — fill the main column (sorted by event date, newest first)
          {
            collection: "talks",
            q: "*",
            query_by: "title",
            per_page: 10,
            sort_by: "event_start_date:desc",
          },
          // Upcoming events — start_date >= today, ascending
          {
            collection: "events",
            q: "*",
            query_by: "name",
            filter_by: `start_date:>=${today}`,
            sort_by: "start_date:asc",
            per_page: 5,
          },
          // Top speakers — is_speaker:true, sort by talk_count desc
          {
            collection: "profiles",
            q: "*",
            query_by: "name",
            filter_by: "is_speaker:true",
            sort_by: "talk_count:desc",
            per_page: 5,
          },
        ],
      })

      const { html, itemCount } = buildEmptyState(results)
      this._itemCount = itemCount
      this._activeIndex = -1
      this._renderResults(html, itemCount)
    } catch (err) {
      // Silently fail for empty state — Typesense may not be running locally
      console.warn("[CommandBarHook] Empty state fetch failed:", err)
      this._results && (this._results.innerHTML = "")
    }
  },

  // -------------------------------------------------------------------------
  // Render
  // -------------------------------------------------------------------------

  _renderResults(html, itemCount) {
    if (!this._results) return
    this._results.innerHTML = html

    // Update ARIA live region
    if (this._live) {
      this._live.textContent =
        itemCount > 0 ? `${itemCount} results` : "No results"
    }

    // Update aria-activedescendant
    this._input && this._input.setAttribute("aria-activedescendant", "")
  },

  // -------------------------------------------------------------------------
  // Keyboard navigation
  // -------------------------------------------------------------------------

  _handleKeydown(e) {
    if (!this._isOpen) return

    switch (e.key) {
      case "Escape":
        e.preventDefault()
        this._close()
        break
      case "ArrowDown":
        e.preventDefault()
        this._moveActive(1)
        break
      case "ArrowUp":
        e.preventDefault()
        this._moveActive(-1)
        break
      case "ArrowRight":
        e.preventDefault()
        this._switchColumn("side")
        break
      case "ArrowLeft":
        e.preventDefault()
        this._switchColumn("main")
        break
      case "Enter":
        e.preventDefault()
        this._activateSelected()
        break
    }
  },

  _moveActive(delta) {
    if (this._itemCount === 0) return

    const items = this._getItems()
    if (items.length === 0) return

    // Remove current active
    if (this._activeIndex >= 0 && items[this._activeIndex]) {
      items[this._activeIndex].classList.remove("command-bar-item--active")
      items[this._activeIndex].setAttribute("aria-selected", "false")
    }

    // Compute next index (clamped, not wrapping)
    let next = this._activeIndex + delta
    if (next < 0) next = 0
    if (next >= items.length) next = items.length - 1

    this._activeIndex = next

    const activeItem = items[this._activeIndex]
    if (activeItem) {
      activeItem.classList.add("command-bar-item--active")
      activeItem.setAttribute("aria-selected", "true")
      activeItem.scrollIntoView({ block: "nearest" })

      // Update aria-activedescendant
      const id = `palette-item-${this._activeIndex}`
      activeItem.id = id
      this._input && this._input.setAttribute("aria-activedescendant", id)
    }
  },

  _getItems() {
    if (!this._results) return []
    return Array.from(this._results.querySelectorAll("[data-index]"))
  },

  _switchColumn(targetCol) {
    const items = this._getItems()
    if (items.length === 0) return

    // Find the first item in the target column
    const targetItems = items.filter(el => el.dataset.col === targetCol)
    if (targetItems.length === 0) return

    // Find global index of the first item in the target column
    const targetItem = targetItems[0]
    const globalIndex = items.indexOf(targetItem)
    if (globalIndex < 0) return

    // Deactivate current
    if (this._activeIndex >= 0 && items[this._activeIndex]) {
      items[this._activeIndex].classList.remove("command-bar-item--active")
      items[this._activeIndex].setAttribute("aria-selected", "false")
    }

    this._activeIndex = globalIndex
    targetItem.classList.add("command-bar-item--active")
    targetItem.setAttribute("aria-selected", "true")
    targetItem.scrollIntoView({ block: "nearest" })

    const id = `palette-item-${this._activeIndex}`
    targetItem.id = id
    this._input && this._input.setAttribute("aria-activedescendant", id)
  },

  _activateSelected() {
    const items = this._getItems()
    if (this._activeIndex < 0 || !items[this._activeIndex]) return
    const item = items[this._activeIndex]
    this._navigateTo(item)
  },

  // -------------------------------------------------------------------------
  // Result click handling
  // -------------------------------------------------------------------------

  _handleResultClick(e) {
    // Walk up from click target to find a [data-path] or [data-see-all] element
    let el = e.target
    while (el && el !== this._results) {
      if (el.dataset && el.dataset.path) {
        e.preventDefault()
        this._navigateTo(el)
        return
      }
      if (el.dataset && el.dataset.seeAll) {
        e.preventDefault()
        this._navigateTo(el, el.dataset.seeAll)
        return
      }
      el = el.parentElement
    }
  },

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  _navigateTo(el, overridePath) {
    const path = overridePath || el.dataset.path || el.dataset.seeAll
    if (!path) return

    this.pushEventTo(this.el, "navigate", { path })
    this._close()
  },
}

export default CommandBarHook
