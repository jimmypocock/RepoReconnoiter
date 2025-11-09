import { Controller } from "@hotwired/stimulus"

// Shrinking navbar on scroll (like Airbnb)
export default class extends Controller {
  static targets = ["topRow", "searchSection", "tagline", "searchInline"]
  static values = {
    threshold: { type: Number, default: 50 } // Scroll threshold in pixels
  }

  connect() {
    this.isInitialLoad = true
    this.handleScroll = this.handleScroll.bind(this)
    this.handleResize = this.handleResize.bind(this)

    // Set initial state immediately without transitions
    this.setInitialState()

    // Enable transitions and listeners after a brief delay
    requestAnimationFrame(() => {
      this.isInitialLoad = false
      window.addEventListener("scroll", this.handleScroll)
      window.addEventListener("resize", this.handleResize)
    })
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
    window.removeEventListener("resize", this.handleResize)
  }

  isMobile() {
    return window.innerWidth < 768 // Tailwind's 'md' breakpoint
  }

  setInitialState() {
    // On mobile, always start condensed
    // On desktop, check scroll position
    if (this.isMobile()) {
      this.shrinkInstant()
    } else {
      const scrolled = window.scrollY > this.thresholdValue
      if (scrolled) {
        this.shrinkInstant()
      } else {
        this.expandInstant()
      }
    }
  }

  handleResize() {
    // Re-evaluate state on resize (e.g., rotating device)
    this.setInitialState()
  }

  handleScroll() {
    // On mobile, always stay condensed
    if (this.isMobile()) {
      this.shrink()
      return
    }

    // On desktop, use scroll-based behavior
    const scrolled = window.scrollY > this.thresholdValue

    if (scrolled) {
      this.shrink()
    } else {
      this.expand()
    }
  }

  shrinkInstant() {
    // On desktop only: hide bottom search section completely
    if (this.hasSearchSectionTarget && !this.isMobile()) {
      this.searchSectionTarget.classList.add("!hidden")
    }
    // On desktop: show inline search by removing md:hidden
    if (this.hasSearchInlineTarget && !this.isMobile()) {
      this.searchInlineTarget.classList.remove("md:hidden")
    }
  }

  expandInstant() {
    // On desktop only: show bottom search section
    if (this.hasSearchSectionTarget && !this.isMobile()) {
      this.searchSectionTarget.classList.remove("!hidden")
    }
    // On desktop: hide inline search by adding md:hidden back
    if (this.hasSearchInlineTarget && !this.isMobile()) {
      this.searchInlineTarget.classList.add("md:hidden")
    }
  }

  shrink() {
    // On desktop only: hide bottom search section completely
    if (this.hasSearchSectionTarget && !this.isMobile()) {
      this.searchSectionTarget.classList.add("!hidden")
    }

    // On desktop: show inline search by removing md:hidden
    if (this.hasSearchInlineTarget && !this.isMobile()) {
      this.searchInlineTarget.classList.remove("md:hidden")
    }
  }

  expand() {
    // On desktop only: show bottom search section
    if (this.hasSearchSectionTarget && !this.isMobile()) {
      this.searchSectionTarget.classList.remove("!hidden")
    }

    // On desktop: hide inline search by adding md:hidden back
    if (this.hasSearchInlineTarget && !this.isMobile()) {
      this.searchInlineTarget.classList.add("md:hidden")
    }
  }
}
