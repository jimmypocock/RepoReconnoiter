class ComparisonsController < ApplicationController
  def index
    # Clean homepage with search input
  end

  def create
    return redirect_to root_path, alert: "Please enter a search query" if query.blank?
    return redirect_to root_path, alert: "Query too long (max 500 characters)" if query.length > 500

    result = comparison  # Save ComparisonCreator result before overwriting @comparison
    session[:newly_created] = result.newly_created
    redirect_to comparison_path(result.record), notice: build_notice(result)
  rescue ComparisonCreator::InvalidQueryError => e
    redirect_to root_path, alert: "Invalid query: #{e.message}"
  rescue ComparisonCreator::NoRepositoriesFoundError => e
    redirect_to root_path, alert: "No repositories found for your query. Try different keywords."
  rescue Octokit::TooManyRequests => e
    redirect_to root_path, alert: "GitHub rate limit exceeded. Please try again in a few minutes."
  rescue Faraday::Error, Faraday::TimeoutError => e
    redirect_to root_path, alert: "Network error occurred. Please check your connection and try again."
  rescue OpenAI::Errors => e
    redirect_to root_path, alert: "AI service temporarily unavailable. Please try again in a few moments."
  rescue StandardError => e
    redirect_to root_path, alert: "Something went wrong. Please try again or contact support if the issue persists."
  end

  def show
    comparison = Comparison.find(params[:id])
    comparison.increment_view_count!
    @comparison = ComparisonPresenter.new(comparison, newly_created: session.delete(:newly_created))
  end

  private

  def build_cache_notice(comparison, similarity)
    if similarity > 0.9
      "Showing cached results from #{helpers.time_ago_in_words(comparison.created_at)} ago"
    else
      "Showing similar query results (#{(similarity * 100).round}% match) from #{helpers.time_ago_in_words(comparison.created_at)} ago"
    end
  end

  def build_notice(result)
    if result.newly_created
      "Analysis complete!"
    else
      build_cache_notice(result.record, result.similarity)
    end
  end

  def comparison
    @comparison ||= ComparisonCreator.call(query: query, force_refresh: force_refresh)
  end

  def force_refresh
    @force_refresh ||= params[:refresh] == "true"
  end

  def query
    @query ||= params[:query].to_s.strip
  end
end
