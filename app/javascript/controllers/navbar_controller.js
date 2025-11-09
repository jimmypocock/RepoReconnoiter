import { Controller } from "@hotwired/stimulus"

// Shrinking navbar on scroll (like Airbnb)
export default class extends Controller {
  static targets = ["topRow", "searchSection", "tagline", "searchInline"]
  static values = {
    threshold: { type: Number, default: 10 }, // Scroll threshold in pixels
    startCondensed: { type: Boolean, default: false } // Start in condensed state
  }

  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    this.isCondensed = false
    this.ticking = false
    this.ignoreScrollUntil = 0 // Timestamp to ignore scroll events until (dead zone)

    // Set initial state based on mobile/desktop and scroll position
    if (this.isMobile()) {
      this.shrinkInstant()
      this.isCondensed = true
    } else if (this.startCondensedValue) {
      // Desktop: Start condensed if explicitly requested (non-homepage pages)
      this.shrinkInstant()
      this.isCondensed = true
    } else if (window.scrollY > this.thresholdValue) {
      // Desktop: If already scrolled down (refresh or anchor link), start condensed
      this.shrinkInstant()
      this.isCondensed = true
    }
    // Desktop at top on homepage starts expanded (default state)

    // Add scroll listener
    window.addEventListener("scroll", this.onScroll.bind(this), { passive: true })
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
