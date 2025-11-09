class ComparisonsController < ApplicationController
  before_action :authenticate_user!, only: [ :create ]
  before_action :check_rate_limit, only: [ :create ]

  def index
    @presenter = BrowseComparisonsPresenter.new(params)
    @pagy, @comparisons = pagy(@presenter.comparisons, items: 20)
  end

  def create
    return redirect_to root_path, alert: "Please enter a search query" if query.blank?
    return redirect_to root_path, alert: "Query too long (max 500 characters)" if query.length > 500

    redirect_to comparison_path(comparison_created.record), notice: build_notice(comparison_created)
  rescue ComparisonCreator::InvalidQueryError => e
    redirect_to root_path, alert: "Invalid query: #{e.message}"
  rescue ComparisonCreator::NoRepositoriesFoundError
    redirect_to root_path, alert: "No repositories found for your query. Try different keywords."
  end

  def show
    comparison = Comparison.find(params[:id])
    comparison.increment_view_count!
    @comparison = ComparisonPresenter.new(comparison, newly_created: session.delete(:newly_created))
  end

  private

  def build_notice(result)
    if result.newly_created
      "Analysis complete!"
    elsif result.similarity > 0.9
      "Showing cached results from #{helpers.time_ago_in_words(result.record.created_at)} ago"
    else
      "Showing similar query results (#{(result.similarity * 100).round}% match) from #{helpers.time_ago_in_words(result.record.created_at)} ago"
    end
  end

  def check_rate_limit
    return if current_user.can_create_comparison?

    redirect_to root_path, alert: "You've reached your daily limit of #{current_user.daily_comparison_limit} comparisons. Try again tomorrow!"
  end

  def comparison_created
    @comparison_created ||= ComparisonCreator.call(query: query, force_refresh: force_refresh, user: current_user).tap do |result|
      session[:newly_created] = result.newly_created
    end
  end

  def force_refresh
    @force_refresh ||= params[:refresh] == "true"
  end

  def query
    @query ||= params[:query].to_s.strip
  end
end
