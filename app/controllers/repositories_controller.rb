class RepositoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_repository, only: [ :show, :create_analysis ]

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def create_analysis
    # Check daily budget
    unless AnalysisDeep.can_create_today?
      flash[:alert] = "Daily deep analysis budget has been exceeded. Please try again tomorrow."
      redirect_to repository_path(@repository) and return
    end

    # Check user rate limit
    unless AnalysisDeep.user_can_create_today?(current_user)
      flash[:alert] = "You have reached your daily limit of #{AnalysisDeep::RATE_LIMIT_PER_USER} deep analyses. Please try again tomorrow."
      redirect_to repository_path(@repository) and return
    end

    # Generate session ID for progress tracking
    @session_id = SecureRandom.uuid

    # Enqueue background job for deep analysis with progress broadcasting
    CreateDeepAnalysisJob.perform_later(current_user.id, @repository.id, @session_id)

    # Return turbo stream to show progress modal
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to repository_path(@repository), notice: "Deep analysis started..." }
    end
  end

  def index
    @repositories = Repository.order(updated_at: :desc).limit(50)

    # Handle search if query present
    if params[:query].present?
      begin
        parsed = GithubUrlParser.parse(params[:query])

        if parsed[:full_name]
          # Try to find existing repo
          @repository = Repository.find_by(full_name: parsed[:full_name])

          # If not found, fetch from GitHub
          unless @repository
            @repository = fetch_repository_from_github(parsed[:full_name])
          end

          # Redirect to repo show page
          redirect_to repository_path(@repository) and return
        end
      rescue GithubUrlParser::InvalidUrlError => e
        flash.now[:alert] = e.message
      rescue => e
        flash.now[:alert] = "Error fetching repository: #{e.message}"
      end
    end
  end

  def show
    @analyses = @repository.analyses.order(created_at: :desc)
    @can_create_analysis = AnalysisDeep.can_create_today? && AnalysisDeep.user_can_create_today?(current_user)
    @remaining_budget = AnalysisDeep.remaining_budget_today
    @user_analyses_today = AnalysisDeep.count_for_user_today(current_user)
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def fetch_repository_from_github(full_name)
    client = Octokit::Client.new(
      access_token: Rails.application.credentials.github&.personal_access_token
    )

    gh_repo = client.repository(full_name)
    repo = Repository.from_github_api(gh_repo.to_attrs)
    repo.save!
    repo
  rescue Octokit::NotFound
    raise "Repository not found on GitHub: #{full_name}"
  rescue => e
    raise "Error fetching from GitHub: #{e.message}"
  end

  def set_repository
    @repository = Repository.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Repository not found"
    redirect_to repositories_path
  end
end
