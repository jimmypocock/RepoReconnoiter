import { Controller } from "@hotwired/stimulus"

// Dropdown controller for navigation menus
// Handles click-to-toggle behavior with click-outside-to-close
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundClose = this.close.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  //--------------------------------------
  // PUBLIC INSTANCE METHODS
  //--------------------------------------

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClose)
  }

  open() {
    // Guard: prevent duplicate listener if already open
    if (!this.menuTarget.classList.contains("hidden")) return

    this.menuTarget.classList.remove("hidden")

    // Delay listener attachment so the opening click doesn't immediately close the menu
    setTimeout(() => {
      document.addEventListener("click", this.boundClose)
    }, 0)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }
}
