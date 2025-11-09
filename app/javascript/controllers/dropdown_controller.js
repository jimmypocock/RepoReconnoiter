import { Controller } from "@hotwired/stimulus"

// Dropdown controller for navigation menus
// Handles click-to-toggle behavior with click-outside-to-close
export default class extends Controller {
  static targets = [ "menu" ]

  connect() {
    this.boundClose = this.close.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    // Add click listener to close when clicking outside
    setTimeout(() => {
      document.addEventListener("click", this.boundClose)
    }, 0)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClose)
  }
}
