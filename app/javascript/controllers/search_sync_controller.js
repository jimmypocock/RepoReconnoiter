import { Controller } from "@hotwired/stimulus"

// Syncs search inputs across the page (homepage hero + navbar)
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Sync all inputs to match the first non-empty one on page load
    const nonEmptyInput = this.inputTargets.find(input => input.value.trim() !== "")
    if (nonEmptyInput) {
      this.syncAll(nonEmptyInput.value)
    }
  }

  // When any input changes, sync all other inputs
  sync(event) {
    const value = event.target.value
    this.syncAll(value)
  }

  syncAll(value) {
    this.inputTargets.forEach(input => {
      if (input.value !== value) {
        input.value = value
      }
    })
  }
}
