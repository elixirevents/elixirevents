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

    // Start at regional view, then fly to venue
    this.map = L.map(this.el, {
      center: [lat, lng],
      zoom: 10,
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

    const marker = L.marker([lat, lng], { icon: markerIcon }).addTo(this.map)
    marker.bindPopup(`<strong>${name}</strong>`, { className: "venue-popup" })

    // Fly in from world view when map becomes visible
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    if (prefersReducedMotion) {
      this.map.setView([lat, lng], 15)
    } else {
      this._flyObserver = new IntersectionObserver(
        (entries) => {
          if (entries[0].isIntersecting) {
            this.map.flyTo([lat, lng], 15, {
              duration: 1.5,
              easeLinearity: 0.25
            })
            this._flyObserver.disconnect()
          }
        },
        { threshold: 0.3 }
      )
      this._flyObserver.observe(this.el)
    }

    // Enable scroll zoom only when mouse is over the map (prevents hijacking page scroll)
    this.el.addEventListener("mouseenter", () => this.map.scrollWheelZoom.enable())
    this.el.addEventListener("mouseleave", () => this.map.scrollWheelZoom.disable())

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
    if (this._flyObserver) {
      this._flyObserver.disconnect()
    }
  }
}

export default VenueMapHook
