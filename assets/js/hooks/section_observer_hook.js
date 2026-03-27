const SectionObserverHook = {
  mounted() {
    this.observer = null
    this.setupObserver()
  },

  setupObserver() {
    const nav = this.el
    const links = nav.querySelectorAll("[data-section-id]")
    const sectionIds = Array.from(links).map(l => l.dataset.sectionId)
    const sections = sectionIds
      .map(id => document.getElementById(id))
      .filter(Boolean)

    if (sections.length === 0) return

    const visibleSections = new Set()

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            visibleSections.add(entry.target.id)
          } else {
            visibleSections.delete(entry.target.id)
          }
        })

        const activeId = sectionIds.find(id => visibleSections.has(id))
        if (activeId) {
          links.forEach(link => {
            link.classList.toggle("active", link.dataset.sectionId === activeId)
          })
        }
      },
      {
        rootMargin: "-80px 0px -60% 0px",
        threshold: 0
      }
    )

    sections.forEach(section => this.observer.observe(section))
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}

export default SectionObserverHook
