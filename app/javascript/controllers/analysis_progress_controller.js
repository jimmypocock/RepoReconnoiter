import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Real-time progress updates for deep analysis
export default class extends Controller {
  static targets = [
    "currentMessage",
    "progressBar",
    "percentage",
    "stepList",
    "errorContainer",
    "errorMessage",
    "closeButton"
  ]

  static values = {
    sessionId: String
  }

  connect() {
    this.completed = false

    // Validate step order matches between DOM and expected flow
    this.validateStepOrder()

    // Subscribe to ActionCable channel for progress updates
    this.subscription = consumer.subscriptions.create(
      {
        channel: "AnalysisProgressChannel",
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

  close() {
    const modal = document.getElementById("analysis-progress-modal")
    if (modal) {
      modal.remove()
    }
  }

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
      this.currentMessageTarget.textContent = data.message || "Deep analysis complete!"
    }

    if (this.hasStepListTarget) {
      const stepElements = this.stepListTarget.querySelectorAll("[data-analysis-step]")
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
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.remove("hidden")
    }

    if (this.hasErrorMessageTarget && data.message) {
      this.errorMessageTarget.textContent = data.message
    }
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
  }

  updateStepList(currentStep) {
    const stepElements = this.stepListTarget.querySelectorAll("[data-analysis-step]")
    const stepOrder = [
      "fetching_readme",
      "fetching_issues",
      "running_analysis",
      "saving_results"
    ]

    const currentStepIndex = stepOrder.indexOf(currentStep)

    stepElements.forEach((element) => {
      const stepName = element.dataset.analysisStep
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

    const domSteps = Array.from(this.stepListTarget.querySelectorAll("[data-analysis-step]"))
      .map(el => el.dataset.analysisStep)

    const expectedSteps = [
      "fetching_readme",
      "fetching_issues",
      "running_analysis",
      "saving_results"
    ]

    if (JSON.stringify(domSteps) !== JSON.stringify(expectedSteps)) {
      console.error("Step order mismatch! DOM steps:", domSteps, "Expected:", expectedSteps)
    }
  }
}
