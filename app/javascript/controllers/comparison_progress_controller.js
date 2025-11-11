import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Real-time progress updates for comparison creation
export default class extends Controller {
  static targets = [
    "currentMessage",
    "progressBar",
    "percentage",
    "stepList",
    "analyzeCount",
    "errorContainer",
    "errorMessage"
  ]

  static values = {
    sessionId: String
  }

  connect() {
    this.retryData = null
    this.completed = false

    // Validate step order matches between DOM and expected flow
    this.validateStepOrder()

    // Subscribe to ActionCable channel for progress updates
    this.subscription = consumer.subscriptions.create(
      {
        channel: "ComparisonProgressChannel",
        session_id: this.sessionIdValue
      },
      {
        received: (data) => this.handleBroadcast(data)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  //--------------------------------------
  // PUBLIC INSTANCE METHODS
  //--------------------------------------

  handleBroadcast(data) {
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
    }
  }

  handleComplete(data) {
    if (this.completed) {
      return
    }
    this.completed = true

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "100%"
    }
    if (this.hasPercentageTarget) {
      this.percentageTarget.textContent = "100%"
    }
    if (this.hasCurrentMessageTarget) {
      this.currentMessageTarget.textContent = data.message || "Analysis complete!"
    }

    if (this.hasStepListTarget) {
      const stepElements = this.stepListTarget.querySelectorAll("[data-comparison-step]")
      stepElements.forEach((element) => {
        const iconContainer = element.querySelector("[data-step-icon]")
        this.setStepCompleted(element, iconContainer)
      })
    }

    if (data.redirect_url) {
      if (this.subscription) {
        this.subscription.unsubscribe()
      }
      window.location.href = data.redirect_url
    }
  }

  handleError(data) {
    this.retryData = data.retry_data

    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.remove("hidden")
    }

    if (this.hasErrorMessageTarget && data.message) {
      this.errorMessageTarget.textContent = data.message
    }
  }

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

    if (this.hasStepListTarget) {
      const stepElements = this.stepListTarget.querySelectorAll("[data-comparison-step]")
      stepElements.forEach((element) => {
        const iconContainer = element.querySelector("[data-step-icon]")
        this.setStepPending(element, iconContainer)
      })
    }
  }

  retry() {
    if (!this.retryData) {
      return
    }

    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.add("hidden")
    }

    this.resetProgress()

    const form = document.createElement("form")
    form.method = "POST"
    form.action = "/comparisons"

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    if (this.retryData.query) {
      const queryInput = document.createElement("input")
      queryInput.type = "hidden"
      queryInput.name = "query"
      queryInput.value = this.retryData.query
      form.appendChild(queryInput)
    }

    document.body.appendChild(form)
    form.submit()
  }

  setStepCompleted(element, iconContainer) {
    element.classList.remove("opacity-40")
    element.classList.add("opacity-100")

    iconContainer.querySelector(".icon-pending").classList.add("hidden")
    iconContainer.querySelector(".icon-current").classList.add("hidden")
    iconContainer.querySelector(".icon-completed").classList.remove("hidden")
  }

  setStepCurrent(element, iconContainer) {
    element.classList.remove("opacity-40")
    element.classList.add("opacity-100")

    iconContainer.querySelector(".icon-pending").classList.add("hidden")
    iconContainer.querySelector(".icon-current").classList.remove("hidden")
    iconContainer.querySelector(".icon-completed").classList.add("hidden")
  }

  setStepPending(element, iconContainer) {
    element.classList.add("opacity-40")
    element.classList.remove("opacity-100")

    iconContainer.querySelector(".icon-pending").classList.remove("hidden")
    iconContainer.querySelector(".icon-current").classList.add("hidden")
    iconContainer.querySelector(".icon-completed").classList.add("hidden")
  }

  updateProgress(data) {
    if (this.hasCurrentMessageTarget && data.message) {
      this.currentMessageTarget.textContent = data.message
    }

    if (this.hasProgressBarTarget && data.percentage !== undefined) {
      const percentage = Math.min(100, Math.max(0, data.percentage))
      this.progressBarTarget.style.width = `${percentage}%`

      if (this.hasPercentageTarget) {
        this.percentageTarget.textContent = `${percentage}%`
      }
    }

    if (this.hasStepListTarget && data.step) {
      this.updateStepList(data.step)
    }

    if (data.step === "analyzing_repositories" && this.hasAnalyzeCountTarget) {
      if (data.current && data.total) {
        this.analyzeCountTarget.textContent = `${data.current} of ${data.total}`
      }
    }
  }

  updateStepList(currentStep) {
    const stepElements = this.stepListTarget.querySelectorAll("[data-comparison-step]")
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
      const stepName = element.dataset.comparisonStep
      const stepIndex = stepOrder.indexOf(stepName)
      const iconContainer = element.querySelector("[data-step-icon]")

      if (stepIndex < currentStepIndex) {
        this.setStepCompleted(element, iconContainer)
      } else if (stepIndex === currentStepIndex) {
        this.setStepCurrent(element, iconContainer)
      } else {
        this.setStepPending(element, iconContainer)
      }
    })
  }

  validateStepOrder() {
    if (!this.hasStepListTarget) return

    const domSteps = Array.from(this.stepListTarget.querySelectorAll("[data-comparison-step]"))
      .map(el => el.dataset.comparisonStep)

    const expectedSteps = [
      "parsing_query",
      "searching_github",
      "merging_results",
      "analyzing_repositories",
      "comparing_repositories",
      "saving_comparison"
    ]

    if (JSON.stringify(domSteps) !== JSON.stringify(expectedSteps)) {
      console.error("Step order mismatch! DOM steps:", domSteps, "Expected:", expectedSteps)
    }
  }
}
