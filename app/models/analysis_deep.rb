class AnalysisDeep < Analysis
  #--------------------------------------
  # CONFIGURATION
  #--------------------------------------

  # Daily budget cap for deep analysis (expensive ~$0.05-0.10 per repo)
  # REQUIRED: Set ANALYSIS_DEEP_DAILY_BUDGET in .env (see .env.example)
  DAILY_BUDGET = ENV.fetch("ANALYSIS_DEEP_DAILY_BUDGET").to_f

  # Rate limit per user per day
  # REQUIRED: Set ANALYSIS_DEEP_RATE_LIMIT_PER_USER in .env (see .env.example)
  RATE_LIMIT_PER_USER = ENV.fetch("ANALYSIS_DEEP_RATE_LIMIT_PER_USER").to_i

  # Default expiration for deep analysis (longer cache since expensive)
  # REQUIRED: Set ANALYSIS_DEEP_EXPIRATION_DAYS in .env (see .env.example)
  DEFAULT_EXPIRATION_DAYS = ENV.fetch("ANALYSIS_DEEP_EXPIRATION_DAYS").to_i

  #--------------------------------------
  # DEEP ANALYSIS FIELDS
  #--------------------------------------
  # - readme_analysis: Comprehensive README review, docs quality, examples, getting started
  # - issues_analysis: Issue patterns, bug trends, maintainer response patterns
  # - maintenance_analysis: Activity level, maintainer responsiveness, project health
  # - adoption_analysis: Integration difficulty, API design quality, migration complexity
  # - security_analysis: CVEs, security practices, vulnerability patterns

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_validation :set_default_expiration, on: :create, if: -> { expires_at.nil? }

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Check if we can create a new deep analysis today without exceeding budget
    # @return [Boolean] true if within budget
    def can_create_today?
      remaining_budget_today > 0
    end

    # Calculate remaining budget for today
    # @return [Float] remaining budget in USD
    def remaining_budget_today
      spent = today.sum(:cost_usd) || 0
      DAILY_BUDGET - spent
    end

    # Get count of deep analyses created by user today
    # @param user [User] the user to check
    # @return [Integer] count of analyses today
    def count_for_user_today(user)
      return 0 if user.nil?

      joins(:repository)
        .where(repositories: { user_id: user.id })
        .today
        .count
    end

    # Check if user has reached their daily rate limit
    # @param user [User] the user to check
    # @return [Boolean] true if user can create another analysis
    def user_can_create_today?(user)
      return false if user.nil?

      count_for_user_today(user) < RATE_LIMIT_PER_USER
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def set_default_expiration
    self.expires_at = DEFAULT_EXPIRATION_DAYS.days.from_now
  end
end
