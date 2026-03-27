const SearchableSelectHook = {
  mounted() {
    this.input = this.el.querySelector("[data-search-input]")
    this.items = this.el.querySelectorAll("[data-search-value]")
    this.noResults = this.el.querySelector("[data-no-results]")

    if (!this.input) return

    this.input.addEventListener("input", () => this.filter())

    // Focus search input when dropdown opens
    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.attributeName === "data-state") {
          const panel = mutation.target
          if (panel.dataset.state === "open") {
            // Small delay to allow panel animation to start
            requestAnimationFrame(() => {
              this.input.value = ""
              this.filter()
              this.input.focus()
            })
          }
        }
      }
    })

    const panel = this.el.querySelector("[role='listbox']")
    if (panel) {
      this.observer.observe(panel, { attributes: true })
    }

    // Keyboard navigation
    this.input.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.input.value = ""
        this.filter()
        // Close the dropdown
        const panel = this.el.querySelector("[role='listbox']")
        if (panel) panel.dataset.state = "closed"
        const trigger = this.el.querySelector("[aria-haspopup]")
        if (trigger) trigger.setAttribute("aria-expanded", "false")
      }
    })
  },

  filter() {
    const query = this.input.value.toLowerCase().trim()
    let visibleCount = 0

    this.items.forEach((item) => {
      const text = item.dataset.searchValue.toLowerCase()
      const match = !query || text.includes(query)
      item.style.display = match ? "" : "none"
      if (match) visibleCount++
    })

    if (this.noResults) {
      this.noResults.style.display = visibleCount === 0 ? "" : "none"
    }
  },

  destroyed() {
    if (this.observer) this.observer.disconnect()
  }
}

export default SearchableSelectHook
