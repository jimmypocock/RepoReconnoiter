import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Real-time progress updates for comparison creation
export default class extends Controller {
  static targets = [
    "modal",
    "currentMessage",
    "progressBar",
    "percentage",
    "stepList",
    "analyzeCount",
    "errorContainer",
    "errorMessage",
    "retryButton"
  ]

  static values = {
    sessionId: String
  }

  connect() {
    this.currentStep = null
    this.retryData = null
    this.completed = false

    // Subscribe to ActionCable channel for progress updates
    this.subscription = consumer.subscriptions.create(
      {
        channel: "ComparisonProgressChannel",
        session_id: this.sessionIdValue
      },
      {
        received: (data) => this.handleBroadcast(data),
        connected: () => console.log(`Connected to ComparisonProgressChannel (session: ${this.sessionIdValue})`),
        disconnected: () => console.log("Disconnected from ComparisonProgressChannel")
      }
    )
  }

  disconnect() {
    // Cleanup: unsubscribe from channel
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  // Handle incoming broadcast from server
  handleBroadcast(data) {
    console.log("Received broadcast:", data)

    switch (data.type) {
      case "progress":
        this.updateProgress(data)
        break
      case "complete":
        this.handleComplete(data)
        break
      case "error":
        this.handleError(data)
        break
      default:
        console.warn("Unknown broadcast type:", data.type)
    }
  }

  // Update progress UI
  updateProgress(data) {
    // Update current message
    if (this.hasCurrentMessageTarget && data.message) {
      this.currentMessageTarget.textContent = data.message
    }

    // Update progress bar
    if (this.hasProgressBarTarget && data.percentage !== undefined) {
      const percentage = Math.min(100, Math.max(0, data.percentage))
      this.progressBarTarget.style.width = `${percentage}%`

      if (this.hasPercentageTarget) {
        this.percentageTarget.textContent = `${percentage}%`
      }
    }

    // Update step list
    if (this.hasStepListTarget && data.step) {
      this.updateStepList(data.step, data)
    }

    // Update analyze count for repository analysis step
    if (data.step === "analyzing_repositories" && this.hasAnalyzeCountTarget) {
      if (data.current && data.total) {
        this.analyzeCountTarget.textContent = `${data.current} of ${data.total}`
      }
    }
  }

  // Update step list icons and states
  updateStepList(currentStep, data) {
    const stepElements = this.stepListTarget.querySelectorAll("[data-step]")
    const stepOrder = [
      "parsing_query",
      "searching_github",
      "merging_results",
      "analyzing_repositories",
      "comparing_repositories",
      "saving_comparison"
    ]

    const currentStepIndex = stepOrder.indexOf(currentStep)

    stepElements.forEach((element) => {
      const stepName = element.dataset.step
      const stepIndex = stepOrder.indexOf(stepName)
      const iconContainer = element.querySelector(".flex-shrink-0")

      if (stepIndex < currentStepIndex) {
        // Completed step
        this.setStepCompleted(element, iconContainer)
      } else if (stepIndex === currentStepIndex) {
        // Current step
        this.setStepCurrent(element, iconContainer)
      } else {
        // Upcoming step
        this.setStepPending(element, iconContainer)
      }
    })
  }

  // Set step as completed (green checkmark)
  setStepCompleted(element, iconContainer) {
    element.classList.remove("opacity-40")
    element.classList.add("opacity-100")

    iconContainer.innerHTML = `
      <svg class="w-6 h-6 text-green-600" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
      </svg>
    `
  }

  // Set step as current (spinning loader)
  setStepCurrent(element, iconContainer) {
    element.classList.remove("opacity-40")
    element.classList.add("opacity-100")

    iconContainer.innerHTML = `
      <svg class="w-6 h-6 text-blue-600 animate-spin" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    `
  }

  // Set step as pending (gray circle)
  setStepPending(element, iconContainer) {
    element.classList.add("opacity-40")
    element.classList.remove("opacity-100")

    iconContainer.innerHTML = `
      <div class="w-6 h-6 rounded-full border-2 border-gray-300"></div>
    `
  }

  // Handle completion - redirect to comparison show page
  handleComplete(data) {
    console.log("Comparison complete:", data)

    // Prevent duplicate redirects - mark as handled
    if (this.completed) {
      console.log("Already completed, ignoring duplicate broadcast")
      return
    }
    this.completed = true

    // Set progress to 100%
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "100%"
    }
    if (this.hasPercentageTarget) {
      this.percentageTarget.textContent = "100%"
    }
    if (this.hasCurrentMessageTarget) {
      this.currentMessageTarget.textContent = data.message || "Analysis complete!"
    }

    // Mark all steps as completed
    const stepElements = this.stepListTarget.querySelectorAll("[data-step]")
    stepElements.forEach((element) => {
      const iconContainer = element.querySelector(".flex-shrink-0")
      this.setStepCompleted(element, iconContainer)
    })

    // Redirect immediately (no artificial delay needed)
    if (data.redirect_url) {
      console.log("Redirecting to:", data.redirect_url)
      // Unsubscribe before redirecting
      if (this.subscription) {
        this.subscription.unsubscribe()
      }
      window.location.href = data.redirect_url
    } else {
      console.error("No redirect_url in completion data:", data)
    }
  }

  // Handle error - show error message and retry button
  handleError(data) {
    console.error("Comparison error:", data)

    // Store retry data for retry button
    this.retryData = data.retry_data

    // Show error container
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.remove("hidden")
    }

    // Set error message
    if (this.hasErrorMessageTarget && data.message) {
      this.errorMessageTarget.textContent = data.message
    }

    // Hide progress bar (optional)
    // if (this.hasProgressBarTarget) {
    //   this.progressBarTarget.parentElement.parentElement.classList.add("opacity-50")
    // }
  }

  // Retry comparison creation
  retry() {
    if (!this.retryData) {
      console.error("No retry data available")
      return
    }

    // Hide error container
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.add("hidden")
    }

    // Reset progress UI
    this.resetProgress()

    // Create form and submit
    const form = document.createElement("form")
    form.method = "POST"
    form.action = "/comparisons"

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add query parameter
    if (this.retryData.query) {
      const queryInput = document.createElement("input")
      queryInput.type = "hidden"
      queryInput.name = "query"
      queryInput.value = this.retryData.query
      form.appendChild(queryInput)
    }

    // Submit form
    document.body.appendChild(form)
    form.submit()
  }

  // Reset progress UI to initial state
  resetProgress() {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "0%"
    }
    if (this.hasPercentageTarget) {
      this.percentageTarget.textContent = "0%"
    }
    if (this.hasCurrentMessageTarget) {
      this.currentMessageTarget.textContent = "Starting..."
    }
    if (this.hasAnalyzeCountTarget) {
      this.analyzeCountTarget.textContent = ""
    }

    // Reset all steps to pending
    const stepElements = this.stepListTarget?.querySelectorAll("[data-step]")
    stepElements?.forEach((element) => {
      const iconContainer = element.querySelector(".flex-shrink-0")
      this.setStepPending(element, iconContainer)
    })
  }
}
