import { Controller } from "@hotwired/stimulus"

// Shrinking navbar on scroll (like Airbnb)
export default class extends Controller {
  static targets = ["topRow", "searchSection", "tagline", "searchInline"]
  static values = {
    threshold: { type: Number, default: 100 }, // Scroll threshold in pixels
    homepage: { type: Boolean, default: false } // True only on homepage (enables scroll behavior)
  }

  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    this.isCondensed = true // Default to condensed (navbar search inline)
    this.ticking = false
    this.ignoreScrollUntil = 0 // Timestamp to ignore scroll events until (dead zone)

    // On mobile, always condensed
    if (this.isMobile()) {
      this.shrinkInstant()
      this.isCondensed = true
    }
    // On homepage desktop: Enable expand/shrink scroll behavior
    else if (this.homepageValue) {
      if (window.scrollY > this.thresholdValue) {
        // If already scrolled down (refresh or anchor link), start condensed
        this.shrinkInstant()
        this.isCondensed = true
      } else {
        // At top of page, start expanded
        this.isCondensed = false
        // Don't call expand() - already in correct state
      }
      // Add scroll listener for homepage only
      window.addEventListener("scroll", this.onScroll.bind(this), { passive: true })
    }
    // On non-homepage desktop: Always condensed, no scroll behavior
    else {
      this.shrinkInstant()
      this.isCondensed = true
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

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  isMobile() {
    return window.innerWidth < 768
  }

  handleScroll() {
    // On mobile, always condensed (no-op)
    if (this.isMobile()) return

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

  shrinkInstant() {
    // Collapse bottom search section immediately (no transition)
    if (this.hasSearchSectionTarget && !this.isMobile()) {
      this.searchSectionTarget.style.maxHeight = "0px"
      this.searchSectionTarget.style.paddingBottom = "0px"
    }
    // Show inline search
    if (this.hasSearchInlineTarget && !this.isMobile()) {
      this.searchInlineTarget.classList.remove("md:hidden")
    }
  }

  expand() {
    // Expand bottom search section with smooth transition
    if (this.hasSearchSectionTarget && !this.isMobile()) {
      this.searchSectionTarget.style.maxHeight = "200px"
      this.searchSectionTarget.style.paddingBottom = "1rem" // pb-4
    }
    // Hide inline search
    if (this.hasSearchInlineTarget && !this.isMobile()) {
      this.searchInlineTarget.classList.add("md:hidden")
    }
  }

  shrink() {
    // Collapse bottom search section with smooth transition
    if (this.hasSearchSectionTarget && !this.isMobile()) {
      this.searchSectionTarget.style.maxHeight = "0px"
      this.searchSectionTarget.style.paddingBottom = "0px"
    }
    // Show inline search
    if (this.hasSearchInlineTarget && !this.isMobile()) {
      this.searchInlineTarget.classList.remove("md:hidden")
    }
  }
}
