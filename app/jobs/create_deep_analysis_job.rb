# CreateDeepAnalysisJob - Background job for asynchronous deep analysis
#
# Handles deep analysis creation in the background with real-time progress updates
# via ActionCable. Orchestrates RepositoryDeepAnalyzer with progress broadcasting.
#
# Usage:
#   CreateDeepAnalysisJob.perform_later(user.id, repository.id, session_id)
class CreateDeepAnalysisJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 2 do |job, error|
    job.broadcast_retry_exhausted(error)
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def broadcast_retry_exhausted(error)
    session_id = arguments[2]
    broadcaster = AnalysisProgressBroadcaster.new(session_id)
    broadcaster.broadcast_error(error_message_for(error))
  end

  def perform(user_id, repository_id, session_id)
    user = User.find(user_id)
    repository = Repository.find(repository_id)
    broadcaster = AnalysisProgressBroadcaster.new(session_id)

    # Give frontend time to connect to ActionCable
    sleep(0.5)

    # Run deep analysis with progress broadcasting
    analyzer = RepositoryDeepAnalyzer.new(broadcaster:)
    result = analyzer.analyze(repository)

    # Step 4: Save results
    broadcaster.broadcast_step("saving_results", message: "Saving analysis results...")
    repository.analyses.create!(
      type: "AnalysisDeep",
      model_used: "gpt-4o",
      readme_analysis: result[:readme_analysis],
      issues_analysis: result[:issues_analysis],
      maintenance_analysis: result[:maintenance_analysis],
      adoption_analysis: result[:adoption_analysis],
      security_analysis: result[:security_analysis],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      is_current: true,
      user:
    )

    broadcaster.broadcast_complete(repository.id)
  rescue => e
    broadcaster.broadcast_error("Error running deep analysis: #{e.message}")
    raise
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def error_message_for(error)
    case error
    when Octokit::NotFound
      "Repository or README not found on GitHub."
    when Octokit::TooManyRequests
      "GitHub rate limit reached. Please try again in a few minutes."
    when Faraday::TimeoutError
      "Request timed out. Please try again."
    else
      "Something went wrong. Please try again."
    end
  end
end
