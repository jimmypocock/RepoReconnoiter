class User < ApplicationRecord
  #--------------------------------------
  # DEVISE MODULES
  #--------------------------------------

  # OAuth-only authentication - no email/password, no registrations, no password resets
  # :database_authenticatable - Required by Devise (even though we don't use passwords)
  # :rememberable - "Remember me" functionality
  # :omniauthable - GitHub OAuth authentication
  devise :database_authenticatable, :rememberable, :omniauthable,
         omniauth_providers: [ :github ]

  # Skip Devise email validations (we use placeholder emails for OAuth)
  validates :email, presence: true, uniqueness: true

  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :whitelisted_user, optional: true
  has_many :ai_costs, dependent: :nullify
  has_many :analyses, dependent: :nullify
  has_many :comparisons, dependent: :nullify

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :github_id, uniqueness: true, allow_nil: true
  validates :github_username, presence: true, if: :github_id?

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def admin?
    allowed_admin_github_ids.include?(github_id.to_s)
  end

  def can_create_comparison?
    return true if admin?
    comparisons.where("created_at > ?", 24.hours.ago).count < daily_comparison_limit
  end

  # Returns AI cost spent this month by this user
  # @return [Float] Cost in USD
  def ai_cost_spent_this_month
    analyses.where("created_at >= ?", Time.current.beginning_of_month)
            .sum(:cost_usd)
            .to_f
  end

  # Returns deep analyses created this month by this user
  # @return [Integer] Count of analyses
  def analyses_count_this_month
    analyses.where("created_at >= ?", Time.current.beginning_of_month).count
  end

  # Returns comparisons created this month by this user
  # @return [Integer] Count of comparisons
  def comparisons_count_this_month
    comparisons.where("created_at >= ?", Time.current.beginning_of_month).count
  end

  # Returns daily comparison limit (currently 20 for all users)
  # @return [Integer] Daily limit
  def daily_comparison_limit
    20 # All users get 20/day for now
  end

  # Returns analyses remaining today (3/day limit)
  # @return [Integer, Float::INFINITY] Remaining analyses for today
  def remaining_analyses_today
    return Float::INFINITY if admin? # Unlimited for admins

    limit = AnalysisDeep::RATE_LIMIT_PER_USER
    used = AnalysisDeep.count_for_user_today(self)
    [ limit - used, 0 ].max
  end

  # Returns comparisons remaining today (20/day limit)
  # @return [Integer, Float::INFINITY] Remaining comparisons for today
  def remaining_comparisons_today
    return Float::INFINITY if admin? # Unlimited for admins

    limit = daily_comparison_limit
    used = comparisons.where("created_at > ?", 24.hours.ago).count
    [ limit - used, 0 ].max
  end

  # Soft delete user and anonymize data
  # Keeps comparisons/analyses for data integrity but removes personal info
  # @return [Boolean] Success status
  def soft_delete!
    transaction do
      update!(
        deleted_at: Time.current,
        email: "deleted_#{id}@example.com",
        github_username: "deleted_user_#{id}",
        github_avatar_url: nil
      )

      # Keep comparisons/analyses for data integrity, but anonymize
      comparisons.update_all(user_id: nil)
      analyses.update_all(user_id: nil)
    end
  end

  # Returns total AI cost spent by this user (all time)
  # @return [Float] Cost in USD
  def total_ai_cost_spent
    analyses.sum(:cost_usd).to_f
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    def from_omniauth(auth)
      # Check whitelist FIRST - reject if not whitelisted
      whitelisted = WhitelistedUser.find_by(github_id: auth.uid.to_i)
      raise "Not whitelisted" unless whitelisted

      # Find or create user by github_id
      user = find_or_initialize_by(github_id: auth.uid.to_i)

      # Update user attributes from GitHub OAuth
      user.assign_attributes(
        provider: auth.provider,
        uid: auth.uid,
        email: auth.info.email || "#{auth.info.nickname}@users.noreply.github.com",
        github_username: auth.info.nickname,
        github_name: auth.info.name,
        github_avatar_url: auth.info.image,
        whitelisted_user_id: whitelisted.id,
        password: Devise.friendly_token[0, 20] # Random password (OAuth users don't use it)
      )

      user.save!
      user
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def allowed_admin_github_ids
    ENV.fetch("ALLOWED_ADMIN_GITHUB_IDS", "").split(",").map(&:strip).reject(&:empty?)
  end
end
