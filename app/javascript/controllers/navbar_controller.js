import { Controller } from "@hotwired/stimulus"

// Shrinking navbar on scroll (like Airbnb)
export default class extends Controller {
  static targets = ["logoText", "searchSection", "searchInline"]
  static values = {
    threshold: { type: Number, default: 144 }, // Scroll threshold in pixels
    homepage: { type: Boolean, default: false } // True only on homepage (enables scroll behavior)
  }

  connect() {
    this.boundOnScroll = this.onScroll.bind(this)
    this.ticking = false
    this.ignoreScrollUntil = 0 // Timestamp to ignore scroll events until (dead zone)

    // On homepage: Check if we should expand (default is condensed from server)
    if (this.homepageValue) {
      if (window.scrollY <= this.thresholdValue) {
        // At top of page, expand immediately (removes navbar-condensed class)
        this.expand()
        this.isCondensed = false
      } else {
        // Already scrolled down, stay condensed (navbar-condensed class already set)
        this.shrinkInstant()
        this.isCondensed = true
      }
      // Add scroll listener for homepage only
      window.addEventListener("scroll", this.boundOnScroll, { passive: true })
    }
    // On non-homepage: Always condensed (navbar-condensed class already set server-side)
    else {
      this.shrinkInstant()
      this.isCondensed = true
    }
  }

  disconnect() {
    window.removeEventListener("scroll", this.boundOnScroll)
  }

  expand() {
    // Show page search section with smooth transition
    if (this.hasSearchSectionTarget) {
      this.searchSectionTarget.style.display = "block"
    }
    // Hide inline navbar search on all screen sizes
    if (this.hasSearchInlineTarget) {
      this.searchInlineTarget.classList.add("hidden")
    }
    // Remove condensed class (logo text shows via CSS on all screens)
    this.element.classList.remove("navbar-condensed")
  }

  handleScroll() {
    // If we're in the dead zone (ignoring scroll events), skip
    if (Date.now() < this.ignoreScrollUntil) return

    const scrollY = window.scrollY

    // Expand when at top
    if (this.isCondensed && scrollY <= this.thresholdValue) {
      this.isCondensed = false
      this.expand()
      // Dead zone: ignore scroll events for 150ms after expanding
      this.ignoreScrollUntil = Date.now() + 150
    }
    // Condense when scrolled down
    else if (!this.isCondensed && scrollY > this.thresholdValue) {
      this.isCondensed = true
      this.shrink()
      // Dead zone: ignore scroll events for 150ms after condensing
      this.ignoreScrollUntil = Date.now() + 150
    }
  }

  onScroll() {
    if (!this.ticking) {
      this.ticking = true
      requestAnimationFrame(() => {
        this.handleScroll()
        this.ticking = false
      })
    }
  }

  shrink() {
    // Hide page search section with smooth transition
    if (this.hasSearchSectionTarget) {
      this.searchSectionTarget.style.display = "none"
    }
    // Show inline navbar search on all screen sizes
    if (this.hasSearchInlineTarget) {
      this.searchInlineTarget.classList.remove("hidden")
    }
    // Add condensed class (CSS hides logo text on small screens)
    this.element.classList.add("navbar-condensed")
  }

  shrinkInstant() {
    // Hide page search section immediately (no transition)
    if (this.hasSearchSectionTarget) {
      this.searchSectionTarget.style.display = "none"
    }
    // Show inline navbar search
    if (this.hasSearchInlineTarget) {
      this.searchInlineTarget.classList.remove("hidden")
    }
    // Add condensed class (CSS hides logo text on small screens)
    this.element.classList.add("navbar-condensed")
  }
}
