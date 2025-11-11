import { Controller } from "@hotwired/stimulus"

// Syncs search inputs across the page (homepage hero + navbar)
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Sync all inputs to match the first non-empty one on page load
    // Handles back button navigation and page refresh with form values
    const nonEmptyInput = this.inputTargets.find(input => input.value.trim() !== "")
    if (nonEmptyInput) {
      this.syncAll(nonEmptyInput.value)
    }
  }

  sync(event) {
    // When any input changes, sync all other inputs
    const value = event.target.value
    this.syncAll(value)
  }

  syncAll(value) {
    // Update all inputs to match the given value
    this.inputTargets.forEach(input => {
      if (input.value !== value) {
        input.value = value
      }
    })
  }
}
