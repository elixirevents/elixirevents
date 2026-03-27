import maplibregl from "maplibre-gl"

// CARTO vector tile styles — same Dark Matter look, smooth vector rendering
const DARK_STYLE = "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
const LIGHT_STYLE = "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json"

const VenueMapHook = {
  mounted() {
    const lat = parseFloat(this.el.dataset.lat)
    const lng = parseFloat(this.el.dataset.lng)
    const name = this.el.dataset.name || "Venue"

    if (isNaN(lat) || isNaN(lng)) return

    const isDark = document.documentElement.dataset.theme === "dark" ||
      (document.documentElement.dataset.theme !== "light" &&
       window.matchMedia("(prefers-color-scheme: dark)").matches)

    this.map = new maplibregl.Map({
      container: this.el,
      style: isDark ? DARK_STYLE : LIGHT_STYLE,
      center: [lng, lat],
      zoom: 14,
      attributionControl: false,
      scrollZoom: false
    })

    // Compact attribution
    this.map.addControl(
      new maplibregl.AttributionControl({ compact: true }),
      "bottom-right"
    )

    // Custom purple marker
    const markerEl = document.createElement("div")
    markerEl.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 36" width="32" height="48">
        <path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 24 12 24s12-15 12-24C24 5.4 18.6 0 12 0z" fill="#8a3897"/>
        <circle cx="12" cy="12" r="5" fill="white" opacity="0.9"/>
      </svg>`
    markerEl.style.cursor = "pointer"

    const popup = new maplibregl.Popup({
      offset: [0, -48],
      closeButton: false,
      className: "venue-popup"
    }).setHTML(`<strong>${name}</strong>`)

    new maplibregl.Marker({ element: markerEl })
      .setLngLat([lng, lat])
      .setPopup(popup)
      .addTo(this.map)

    // Enable scroll zoom on hover, disable on leave
    this.el.addEventListener("mouseenter", () => this.map.scrollZoom.enable())
    this.el.addEventListener("mouseleave", () => this.map.scrollZoom.disable())

    // Watch for theme changes
    this._themeObserver = new MutationObserver(() => {
      const nowDark = document.documentElement.dataset.theme === "dark" ||
        (document.documentElement.dataset.theme !== "light" &&
         window.matchMedia("(prefers-color-scheme: dark)").matches)

      this.map.setStyle(nowDark ? DARK_STYLE : LIGHT_STYLE)
    })

    this._themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme"]
    })
  },

  destroyed() {
    if (this.map) {
      this.map.remove()
    }
    if (this._themeObserver) {
      this._themeObserver.disconnect()
    }
  }
}

export default VenueMapHook
