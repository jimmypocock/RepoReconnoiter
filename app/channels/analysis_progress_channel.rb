# AnalysisProgressChannel - Real-time progress updates for deep analysis
#
# Streams progress events from CreateDeepAnalysisJob to the client browser.
# Uses session_id for stream isolation (multiple concurrent analyses).
#
# Client subscription example (Stimulus):
#   consumer.subscriptions.create(
#     { channel: "AnalysisProgressChannel", session_id: "abc-123" },
#     { received: (data) => this.updateProgress(data) }
#   )
class AnalysisProgressChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user
    return reject unless params[:session_id].present?

    stream_from "analysis_progress_#{params[:session_id]}"
  end
end
