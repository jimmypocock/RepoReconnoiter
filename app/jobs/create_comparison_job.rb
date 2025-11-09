# CreateComparisonJob - Background job for asynchronous comparison creation
#
# Handles comparison creation in the background with real-time progress updates
# via ActionCable. Orchestrates ComparisonCreator with progress broadcasting.
#
# Usage:
#   CreateComparisonJob.perform_later(user.id, "Rails background jobs", session_id)
class CreateComparisonJob < ApplicationJob
  queue_as :default

  # Don't retry on validation errors - these are user-facing issues
  # discard_on ComparisonCreator::InvalidQueryError
  # discard_on ComparisonCreator::NoRepositoriesFoundError

  # Note: Could add retry_on for specific API errors in the future:
  # retry_on Octokit::TooManyRequests, wait: 1.hour, attempts: 3
  # retry_on Faraday::TimeoutError, wait: 30.seconds, attempts: 3

  def perform(user_id, query, session_id)
    Rails.logger.info "🚀 CreateComparisonJob START - session: #{session_id}, query: #{query}"

    user = User.find(user_id)

    # Create comparison with progress broadcasting (may return cached result)
    result = ComparisonCreator.new(
      query: query,
      user: user,
      session_id: session_id
    ).call

    Rails.logger.info "✅ CreateComparisonJob DONE - comparison_id: #{result.record.id}, newly_created: #{result.newly_created}"

    # Always broadcast completion with redirect URL (whether new or cached)
    # The broadcaster will handle the redirect to the comparison show page
    ComparisonProgressBroadcaster.new(session_id).broadcast_complete(result.record.id)

    Rails.logger.info "📡 Broadcast complete sent for session: #{session_id}"
  end
end
