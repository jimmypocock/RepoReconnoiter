class Repository < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------
  has_many :analyses, dependent: :destroy
  has_many :queued_analyses, dependent: :destroy
  has_many :repository_categories, dependent: :destroy
  has_many :categories, through: :repository_categories

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------
  validates :github_id, presence: true, uniqueness: true
  validates :node_id, presence: true, uniqueness: true
  validates :full_name, presence: true, uniqueness: true
  validates :name, presence: true
  validates :html_url, presence: true

  #--------------------------------------
  # SCOPES
  #--------------------------------------
  scope :active, -> { where(archived: false, disabled: false) }
  scope :recently_updated, -> { order(github_pushed_at: :desc) }
  scope :popular, -> { order(stargazers_count: :desc) }
  scope :by_language, ->(language) { where(language: language) }
  scope :needs_analysis, -> {
    where("last_analyzed_at IS NULL OR last_analyzed_at < ?", 7.days.ago)
  }

  #--------------------------------------
  # INSTANCE METHODS
  #--------------------------------------
  def needs_analysis?
    return true if last_analyzed_at.nil?
    return true if readme_changed?
    return true if last_analyzed_at < 7.days.ago
    return true if stargazers_count > (last_analysis&.stargazers_at_analysis || 0) * 1.5
    false
  end

  def readme_changed?
    # If we have a cached README but no SHA, assume it changed
    return true if readme_content.present? && readme_sha.blank?

    # Compare current SHA with cached SHA (would need to fetch from API)
    false # Placeholder - implement when fetching README
  end

  def current_analysis
    analyses.where(is_current: true).order(created_at: :desc).first
  end

  def last_analysis
    analyses.order(created_at: :desc).first
  end

  def trending_score
    # Simple trending score based on stars and recent activity
    days_since_created = (Time.current - github_created_at) / 1.day
    return 0 if days_since_created.zero?

    (stargazers_count / days_since_created).round(2)
  end

  def display_name
    full_name
  end

  def github_url
    html_url
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------
  class << self
    def from_github_api(data)
      find_or_initialize_by(github_id: data[:id]).tap do |repo|
        repo.assign_attributes(
          node_id: data[:node_id],
          full_name: data[:full_name],
          name: data[:name],
          description: data[:description],
          html_url: data[:html_url],
          homepage_url: data[:homepage],
          clone_url: data[:clone_url],

          # Owner info
          owner_login: data[:owner][:login],
          owner_avatar_url: data[:owner][:avatar_url],
          owner_type: data[:owner][:type],

          # Stats
          stargazers_count: data[:stargazers_count] || 0,
          forks_count: data[:forks_count] || 0,
          open_issues_count: data[:open_issues_count] || 0,
          watchers_count: data[:watchers_count] || 0,
          size: data[:size],

          # Technical metadata
          language: data[:language],
          topics: data[:topics] || [],
          license: data.dig(:license, :key),
          default_branch: data[:default_branch] || "main",

          # Properties
          is_fork: data[:fork] || false,
          is_template: data[:is_template] || false,
          archived: data[:archived] || false,
          disabled: data[:disabled] || false,
          visibility: data[:visibility] || "public",

          # GitHub timestamps
          github_created_at: data[:created_at],
          github_updated_at: data[:updated_at],
          github_pushed_at: data[:pushed_at],

          # Our tracking
          last_fetched_at: Time.current,
          search_score: data[:score]
        )
        repo.fetch_count += 1 if repo.persisted?
      end
    end
  end
end
