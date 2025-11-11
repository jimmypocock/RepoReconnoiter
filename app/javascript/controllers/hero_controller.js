import { Controller } from "@hotwired/stimulus"

// Manages hero section CTA analytics
export default class extends Controller {
  // Handle CTA clicks for analytics
  ctaClick(event) {
    const action = event.currentTarget.dataset.actionParam
    this.trackCTAAnalytics(action)
  }

  // Track CTA clicks with Microsoft Clarity
  trackCTAAnalytics(action) {
    if (window.clarity) {
      window.clarity("event", "hero_cta_clicked", { action: action })
    }
  }
}
