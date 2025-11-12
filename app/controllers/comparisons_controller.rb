class ComparisonsController < ApplicationController
  before_action :authenticate_user!, only: [ :create ]
  before_action :check_rate_limit, only: [ :create ]

  def index
    @presenter = SearchComparisonsPresenter.new(params)
    @pagy, @comparisons = pagy(@presenter.comparisons, limit: 20)
    @comparisons_count = @presenter.comparisons.count

    # Fetch repositories for analyses tab
    @repositories = Repository.order(updated_at: :desc).limit(50)
    @repositories_count = Repository.count
  end

  def create
    return redirect_to root_path, alert: "Please enter a search query" if query.blank?
    return redirect_to root_path, alert: "Query too long (max 500 characters)" if query.length > 500

    # Generate unique session ID for progress tracking
    @session_id = SecureRandom.uuid
    session[:comparison_session_id] = @session_id

    CreateComparisonJob.perform_later(current_user.id, query, @session_id)

    # Respond with Turbo Stream to show
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path, notice: "Creating your comparison..." }
    end
  end

  def show
    comparison = Comparison.find(params[:id])
    comparison.increment_view_count!
    @comparison = ComparisonPresenter.new(comparison, current_user, newly_created: session.delete(:newly_created))
  end

  private

  def check_rate_limit
    return if current_user.can_create_comparison?

    redirect_to root_path, alert: "You've reached your daily limit of #{current_user.daily_comparison_limit} comparisons. Try again tomorrow!"
  end

  def query
    @query ||= params[:query].to_s.strip
  end
end
