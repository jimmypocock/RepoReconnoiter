# CreateComparisonJob - Background job for asynchronous comparison creation
#
# Handles comparison creation in the background with real-time progress updates
# via ActionCable. Orchestrates ComparisonCreator with progress broadcasting.
#
# Usage:
#   CreateComparisonJob.perform_later(user.id, "Rails background jobs", session_id)
class CreateComparisonJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 2 do |job, error|
    job.broadcast_retry_exhausted(error)
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def broadcast_retry_exhausted(error)
    user_id, query, session_id = arguments
    broadcaster = ComparisonProgressBroadcaster.new(session_id)
    status_record = ComparisonStatus.find_by(session_id: session_id)

    Sentry.capture_exception(error, extra: {
      job: "CreateComparisonJob",
      user_id:,
      query:,
      session_id:,
      executions:
    })

    error_msg = error_message_for(error)
    status_record&.fail!(error_msg)
    broadcaster.broadcast_error(error_msg)
  end

  def perform(user_id, query, session_id)
    user = User.find(user_id)
    broadcaster = ComparisonProgressBroadcaster.new(session_id)
    status_record = ComparisonStatus.find_by(session_id: session_id)

    result = ComparisonCreator.new(
      query: query,
      user: user,
      session_id: session_id
    ).call

    # Update status to completed
    status_record&.complete!(result.record)

    broadcaster.broadcast_complete(result.record.id)
  rescue ComparisonCreator::InvalidQueryError => e
    error_msg = "Invalid query: #{e.message}"
    status_record&.fail!(error_msg)
    broadcaster.broadcast_error(error_msg)
  rescue ComparisonCreator::NoRepositoriesFoundError => e
    error_msg = "No repositories found. Try a different query."
    status_record&.fail!(error_msg)
    broadcaster.broadcast_error(error_msg)
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def error_message_for(error)
    case error
    when Octokit::TooManyRequests
      "GitHub rate limit reached. Please try again in a few minutes."
    when Faraday::TimeoutError
      "Request timed out. Please try again."
    else
      "Something went wrong. Please try again."
    end
  end
end
