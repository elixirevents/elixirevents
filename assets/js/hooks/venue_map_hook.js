import L from "leaflet"

// Custom purple marker SVG matching brand color
const MARKER_SVG = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 36" width="28" height="42">
  <path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 24 12 24s12-15 12-24C24 5.4 18.6 0 12 0z" fill="#8a3897"/>
  <circle cx="12" cy="12" r="5" fill="white" opacity="0.9"/>
</svg>`

const VenueMapHook = {
  mounted() {
    const lat = parseFloat(this.el.dataset.lat)
    const lng = parseFloat(this.el.dataset.lng)
    const name = this.el.dataset.name || "Venue"

    if (isNaN(lat) || isNaN(lng)) return

    // Use CartoDB Dark Matter tiles — free, no API key, dark themed
    const darkTiles = L.tileLayer(
      "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
      {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; <a href="https://carto.com/">CARTO</a>',
        subdomains: "abcd",
        maxZoom: 19
      }
    )

    const lightTiles = L.tileLayer(
      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
      {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; <a href="https://carto.com/">CARTO</a>',
        subdomains: "abcd",
        maxZoom: 19
      }
    )

    // Detect current theme
    const isDark = document.documentElement.dataset.theme === "dark" ||
      (document.documentElement.dataset.theme !== "light" &&
       window.matchMedia("(prefers-color-scheme: dark)").matches)

    this.map = L.map(this.el, {
      center: [lat, lng],
      zoom: 15,
      zoomControl: false,
      attributionControl: true,
      scrollWheelZoom: false,
      dragging: !L.Browser.mobile
    })

    // Add the appropriate tile layer
    if (isDark) {
      darkTiles.addTo(this.map)
    } else {
      lightTiles.addTo(this.map)
    }

    // Custom marker icon
    const markerIcon = L.divIcon({
      html: MARKER_SVG,
      className: "venue-marker",
      iconSize: [28, 42],
      iconAnchor: [14, 42],
      popupAnchor: [0, -42]
    })

    L.marker([lat, lng], { icon: markerIcon })
      .addTo(this.map)
      .bindPopup(`<strong>${name}</strong>`, { className: "venue-popup" })

    // Move attribution to bottom-right, keep it subtle
    this.map.attributionControl.setPrefix("")

    // Watch for theme changes
    this._themeObserver = new MutationObserver(() => {
      const nowDark = document.documentElement.dataset.theme === "dark" ||
        (document.documentElement.dataset.theme !== "light" &&
         window.matchMedia("(prefers-color-scheme: dark)").matches)

      if (nowDark && this.map.hasLayer(lightTiles)) {
        this.map.removeLayer(lightTiles)
        darkTiles.addTo(this.map)
      } else if (!nowDark && this.map.hasLayer(darkTiles)) {
        this.map.removeLayer(darkTiles)
        lightTiles.addTo(this.map)
      }
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
