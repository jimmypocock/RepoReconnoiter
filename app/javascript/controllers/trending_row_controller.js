import { Controller } from "@hotwired/stimulus"

// Trending row controller for horizontal scroll and collapse behavior
export default class extends Controller {
  static targets = [ "container", "scroll" ]
  static values = { hasFilters: Boolean }

  connect() {
    this.updateHeight()
  }

  hasFiltersValueChanged() {
    this.updateHeight()
  }

  updateHeight() {
    if (this.hasFiltersValue) {
      // Collapse to smaller height when filters are active
      this.containerTarget.classList.add("h-32")
      this.containerTarget.classList.remove("h-auto")
    } else {
      // Full height when no filters
      this.containerTarget.classList.remove("h-32")
      this.containerTarget.classList.add("h-auto")
    }
  }
}
