import { tinykeys } from "tinykeys"

export function initGlobalShortcuts() {
  tinykeys(window, {
    "$mod+k": (event) => {
      event.preventDefault()
      window.dispatchEvent(new CustomEvent("toggle-palette"))
    },
  })
}
