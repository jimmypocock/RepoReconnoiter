import { Controller } from "@hotwired/stimulus"

// Manages quick action bar and mobile FAB menu
export default class extends Controller {
  static targets = [ "menu", "backdrop" ]

  // Toggle mobile FAB menu
  toggleMenu(event) {
    event.preventDefault()

    if (this.hasMenuTarget) {
      const isVisible = !this.menuTarget.classList.contains("hidden")

      if (isVisible) {
        this.hideMenu()
      } else {
        this.showMenu()
      }
    }
  }

  // Show menu (mobile)
  showMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("hidden")
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
    }
  }

  // Hide menu (mobile)
  hideMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden")
    }
  }

  // Open comparison form (switches to comparisons tab and focuses search)
  openComparison(event) {
    event.preventDefault()
    this.hideMenu()

    const tabsController = this.application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller~='tabs']"),
      "tabs"
    )

    if (tabsController) {
      tabsController.activateTab("comparisons")
      tabsController.updateURL("comparisons")
    }

    // Focus search input
    const searchInput = document.querySelector("[data-tab='comparisons'] input[type='text']")
    if (searchInput) {
      searchInput.focus()
    }
  }

  // Open analysis form (switches to analyses tab and focuses input)
  openAnalysis(event) {
    event.preventDefault()
    this.hideMenu()

    const tabsController = this.application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller~='tabs']"),
      "tabs"
    )

    if (tabsController) {
      tabsController.activateTab("analyses")
      tabsController.updateURL("analyses")
    }

    // Focus repo URL input
    const repoInput = document.querySelector("[data-tab='analyses'] input[type='text']")
    if (repoInput) {
      repoInput.focus()
    }
  }
}
