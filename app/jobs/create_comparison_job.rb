# CreateComparisonJob - Background job for asynchronous comparison creation
#
# Handles comparison creation in the background with real-time progress updates
# via ActionCable. Orchestrates ComparisonCreator with progress broadcasting.
#
# Usage:
#   CreateComparisonJob.perform_later(user.id, "Rails background jobs", session_id)
class CreateComparisonJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 2 do |job, error|
    job.broadcast_retry_exhausted(error)
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def broadcast_retry_exhausted(error)
    session_id = arguments[2]
    broadcaster = ComparisonProgressBroadcaster.new(session_id)
    broadcaster.broadcast_error(error_message_for(error))
  end

  def perform(user_id, query, session_id)
    user = User.find(user_id)
    broadcaster = ComparisonProgressBroadcaster.new(session_id)

    result = ComparisonCreator.new(
      query: query,
      user: user,
      session_id: session_id
    ).call

    broadcaster.broadcast_complete(result.record.id)
  rescue ComparisonCreator::InvalidQueryError => e
    broadcaster.broadcast_error("Invalid query: #{e.message}")
  rescue ComparisonCreator::NoRepositoriesFoundError
    broadcaster.broadcast_error("No repositories found. Try a different query.")
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
