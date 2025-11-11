# ComparisonProgressBroadcaster - Broadcasts comparison creation progress via ActionCable
#
# Encapsulates all progress broadcasting logic for the comparison pipeline.
# Sends real-time updates to the client via ComparisonProgressChannel.
#
# Usage:
#   broadcaster = ComparisonProgressBroadcaster.new(session_id)
#   broadcaster.broadcast_step("parsing_query", message: "Parsing your query...")
#   broadcaster.broadcast_step("analyzing_repositories", current: 3, total: 15, message: "Analyzing sidekiq/sidekiq...")
#   broadcaster.broadcast_complete(comparison_id)
#   broadcaster.broadcast_error("No repositories found", retry_data: { query: "..." })
class ComparisonProgressBroadcaster
  attr_reader :session_id

  def initialize(session_id)
    @session_id = session_id
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Broadcast completion with redirect URL
  #
  # @param comparison_id [Integer] ID of created comparison
  def broadcast_complete(comparison_id)
    return unless session_id.present?

    payload = {
      type: "complete",
      comparison_id: comparison_id,
      redirect_url: Rails.application.routes.url_helpers.comparison_path(comparison_id),
      message: "Analysis complete!",
      timestamp: Time.current.iso8601
    }

    broadcast(payload)
  end

  # Broadcast error state with optional retry data
  #
  # @param message [String] User-friendly error message
  # @param retry_data [Hash] Data needed to retry the operation
  def broadcast_error(message, retry_data: {})
    return unless session_id.present?

    payload = {
      type: "error",
      message: message,
      retry_data: retry_data,
      timestamp: Time.current.iso8601
    }

    broadcast(payload)
  end

  # Broadcast a progress step update
  #
  # @param step [String] Step identifier (parsing_query, searching_github, etc.)
  # @param data [Hash] Additional step data
  #   @option data [String] :message User-facing message
  #   @option data [Integer] :current Current item number (for loops)
  #   @option data [Integer] :total Total items (for loops)
  #   @option data [Integer] :percentage Progress percentage (0-100)
  def broadcast_step(step, data = {})
    return unless session_id.present?

    payload = {
      type: "progress",
      step: step,
      message: data[:message] || "Processing...",
      current: data[:current],
      total: data[:total],
      percentage: data[:percentage] || calculate_percentage(step, data),
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

  # Calculate percentage based on step and current/total
  def calculate_percentage(step, data)
    # If current/total provided, calculate from that
    if data[:current] && data[:total] && data[:total] > 0
      base_percentage = step_base_percentage(step)
      step_range = step_percentage_range(step)
      progress_in_step = (data[:current].to_f / data[:total]) * step_range
      (base_percentage + progress_in_step).round
    else
      # Otherwise use fixed percentage per step
      step_base_percentage(step)
    end
  end

  # Base percentage at the start of each step
  def step_base_percentage(step)
    case step
    when "parsing_query"
      0
    when "searching_github"
      10
    when "merging_results"
      20
    when "analyzing_repositories"
      30
    when "comparing_repositories"
      80
    when "saving_comparison"
      95
    else
      0
    end
  end

  # Percentage range allocated to each step
  def step_percentage_range(step)
    case step
    when "parsing_query"
      10
    when "searching_github"
      10
    when "merging_results"
      10
    when "analyzing_repositories"
      50 # Biggest chunk - this is the slow part
    when "comparing_repositories"
      15
    when "saving_comparison"
      5
    else
      0
    end
  end

  def stream_name
    "comparison_progress_#{session_id}"
  end
end
