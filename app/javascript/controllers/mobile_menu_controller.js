import { Controller } from "@hotwired/stimulus"

// Mobile menu controller for hamburger navigation
// Simple toggle behavior for mobile menu
export default class extends Controller {
  static targets = [ "menu" ]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }
}
