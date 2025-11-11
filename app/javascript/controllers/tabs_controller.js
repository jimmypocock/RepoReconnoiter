import { Controller } from "@hotwired/stimulus"

// Manages tab switching, URL sync, and localStorage memory
export default class extends Controller {
  static targets = [ "tab", "panel" ]
  static values = {
    default: { type: String, default: "comparisons" }
  }

  connect() {
    this.restoreOrSyncTab()
  }

  // Restore last active tab or sync from URL
  restoreOrSyncTab() {
    const urlParams = new URLSearchParams(window.location.search)
    const urlTab = urlParams.get("tab")

    if (urlTab) {
      this.activateTab(urlTab)
    } else {
      const lastTab = localStorage.getItem("last_active_tab") || this.defaultValue
      this.activateTab(lastTab)
    }
  }

  // Handle tab click
  switch(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab

    this.activateTab(tab)
    this.updateURL(tab)
    this.saveToLocalStorage(tab)
    this.trackAnalytics(tab)
  }

  // Show active tab, hide others
  activateTab(tabName) {
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === tabName
      this.updateTabButton(tab, isActive)
    })

    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.tab === tabName
      panel.classList.toggle("hidden", !isActive)
    })
  }

  // Update tab button styling
  updateTabButton(tab, isActive) {
    const activeClasses = [ "border-blue-600", "text-blue-600", "font-semibold" ]
    const inactiveClasses = [ "text-gray-600", "border-transparent", "hover:text-gray-900", "hover:border-gray-300" ]

    if (isActive) {
      tab.classList.add(...activeClasses)
      tab.classList.remove(...inactiveClasses)
      tab.setAttribute("aria-selected", "true")
    } else {
      tab.classList.remove(...activeClasses)
      tab.classList.add(...inactiveClasses)
      tab.setAttribute("aria-selected", "false")
    }
  }

  // Update URL without reload
  updateURL(tab) {
    const url = new URL(window.location)
    url.searchParams.set("tab", tab)
    window.history.pushState({}, "", url)
  }

  // Save preference
  saveToLocalStorage(tab) {
    localStorage.setItem("last_active_tab", tab)
  }

  // Track with Microsoft Clarity
  trackAnalytics(tab) {
    if (window.clarity) {
      window.clarity("event", "tab_switched", { tab: tab })
    }
  }
}
