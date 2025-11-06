import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="infinite-scroll"
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.observer = new IntersectionObserver(
      entries => this.handleIntersection(entries),
      {
        threshold: 0.5,
        rootMargin: "100px"
      }
    )

    if (this.hasLinkTarget) {
      this.observer.observe(this.linkTarget)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // Automatically click the "Load More" link when it becomes visible
        this.linkTarget.click()

        // Stop observing this link since we've triggered it
        this.observer.unobserve(this.linkTarget)
      }
    })
  }
}
