import { Controller } from "@hotwired/stimulus"

// Infinite scroll controller for pagination
// Auto-loads next page when scrolled near bottom
export default class extends Controller {
  static targets = ["load", "previous", "trigger"]

  connect() {
    // Hide pagination buttons when JS is enabled (progressive enhancement)
    if (this.hasPreviousTarget) {
      this.previousTarget.style.display = "none"
    }

    if (this.hasLoadTarget) {
      this.loadTarget.style.display = "none"
    }

    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      {
        threshold: 0.5,
        rootMargin: "100px"
      }
    )

    if (this.hasTriggerTarget) {
      this.observer.observe(this.triggerTarget)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersection(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting && this.hasLoadTarget) {
        // Auto-click the load button when trigger becomes visible
        this.loadTarget.click()

        // Stop observing
        if (this.hasTriggerTarget) {
          this.observer.unobserve(this.triggerTarget)
        }
      }
    })
  }
}
