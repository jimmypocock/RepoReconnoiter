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
    allowed_admin_github_ids = ENV.fetch("MISSION_CONTROL_ADMIN_IDS", "").split(",").map(&:strip).reject(&:empty?)
    allowed_admin_github_ids.include?(github_id.to_s)
  end

  def can_create_comparison?
    comparisons.where("created_at > ?", 24.hours.ago).count < daily_comparison_limit
  end

  def daily_comparison_limit
    20 # All users get 20/day for now
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
end
