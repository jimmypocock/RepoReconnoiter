# ComparisonProgressChannel - Real-time progress updates for comparison creation
#
# Streams progress events from CreateComparisonJob to the client browser.
# Uses session_id for stream isolation (multiple concurrent comparisons).
#
# Client subscription example (Stimulus):
#   consumer.subscriptions.create(
#     { channel: "ComparisonProgressChannel", session_id: "abc-123" },
#     { received: (data) => this.updateProgress(data) }
#   )
class ComparisonProgressChannel < ApplicationCable::Channel
  def subscribed
    # Validate session_id parameter exists
    if params[:session_id].present?
      # Stream from unique channel per session
      stream_from "comparison_progress_#{params[:session_id]}"
      Rails.logger.info "ComparisonProgressChannel: Subscribed to session #{params[:session_id]}"
    else
      reject
      Rails.logger.warn "ComparisonProgressChannel: Rejected subscription - missing session_id"
    end
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed
    Rails.logger.info "ComparisonProgressChannel: Unsubscribed from session #{params[:session_id]}"
  end
end
