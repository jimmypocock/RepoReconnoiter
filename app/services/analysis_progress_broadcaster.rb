# AnalysisProgressBroadcaster - Broadcasts deep analysis progress via ActionCable
#
# Encapsulates all progress broadcasting logic for deep analysis.
# Sends real-time updates to the client via AnalysisProgressChannel.
#
# Usage:
#   broadcaster = AnalysisProgressBroadcaster.new(session_id)
#   broadcaster.broadcast_step("fetching_readme", message: "Fetching README...")
#   broadcaster.broadcast_step("running_analysis", percentage: 75, message: "Running AI analysis...")
#   broadcaster.broadcast_complete(repository_id)
#   broadcaster.broadcast_error("Failed to fetch README")
class AnalysisProgressBroadcaster
  attr_reader :session_id

  def initialize(session_id)
    @session_id = session_id
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Broadcast completion with redirect URL
  #
  # @param repository_id [Integer] ID of analyzed repository
  def broadcast_complete(repository_id)
    return unless session_id.present?

    payload = {
      type: "complete",
      repository_id: repository_id,
      redirect_url: Rails.application.routes.url_helpers.repository_path(repository_id),
      message: "Deep analysis complete!",
      timestamp: Time.current.iso8601
    }

    broadcast(payload)
  end

  # Broadcast error state
  #
  # @param message [String] User-friendly error message
  def broadcast_error(message)
    return unless session_id.present?

    payload = {
      type: "error",
      message: message,
      timestamp: Time.current.iso8601
    }

    broadcast(payload)
  end

  # Broadcast a progress step update
  #
  # @param step [String] Step identifier (fetching_readme, fetching_issues, running_analysis, saving_results)
  # @param data [Hash] Additional step data
  #   @option data [String] :message User-facing message
  #   @option data [Integer] :percentage Progress percentage (0-100)
  def broadcast_step(step, data = {})
    return unless session_id.present?

    payload = {
      type: "progress",
      step: step,
      message: data[:message] || "Processing...",
      percentage: data[:percentage] || step_base_percentage(step),
      timestamp: Time.current.iso8601
    }

    broadcast(payload)
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def broadcast(payload)
    ActionCable.server.broadcast(stream_name, payload)
  end

  # Base percentage at the start of each step
  def step_base_percentage(step)
    case step
    when "fetching_readme"
      0
    when "fetching_issues"
      20
    when "running_analysis"
      40
    when "saving_results"
      90
    else
      0
    end
  end

  def stream_name
    "analysis_progress_#{session_id}"
  end
end
