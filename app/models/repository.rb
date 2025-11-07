class Repository < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  has_many :analyses, dependent: :restrict_with_error
  has_many :comparison_repositories, dependent: :restrict_with_error
  has_many :comparisons, through: :comparison_repositories
  has_many :queued_analyses, dependent: :restrict_with_error
  has_many :repository_categories, dependent: :restrict_with_error
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
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def needs_analysis?
    return true if last_analyzed_at.nil?
    return true if readme_changed?
    return true if last_analyzed_at < 7.days.ago
    false
  end

  def readme_changed?
    return false if readme_sha.blank?  # No cached README to compare
    # If cached README exists, check if SHA changed (would need to fetch from GitHub API)
    false  # For now, rely on time-based re-analysis
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------
  class << self
    # Maps our database columns to GitHub API response keys
    # Format: { our_column: api_column } or { our_column: [:nested, :keys] }
    GITHUB_ATTRIBUTE_MAP = {
      # Basic fields
      node_id: :node_id,
      full_name: :full_name,
      name: :name,
      description: :description,
      html_url: :html_url,
      homepage_url: :homepage,
      clone_url: :clone_url,
      language: :language,
      size: :size,

      # Owner info (nested)
      owner_login: [ :owner, :login ],
      owner_avatar_url: [ :owner, :avatar_url ],
      owner_type: [ :owner, :type ],

      # License (nested)
      license: [ :license, :key ],

      # GitHub timestamps
      github_created_at: :created_at,
      github_updated_at: :updated_at,
      github_pushed_at: :pushed_at
    }.freeze

    # Default values for fields that may be missing
    ATTRIBUTE_DEFAULTS = {
      stargazers_count: 0,
      forks_count: 0,
      open_issues_count: 0,
      watchers_count: 0,
      topics: [],
      default_branch: "main",
      is_fork: false,
      is_template: false,
      archived: false,
      disabled: false,
      visibility: "public"
    }.freeze

    def from_github_api(data)
      find_or_initialize_by(github_id: data[:id]).tap do |repo|
        repo.assign_attributes(extract_github_attributes(data))
        repo.fetch_count += 1 if repo.persisted?
      end
    end

    private

    #--------------------------------------
    # PRIVATE CLASS METHODS
    #--------------------------------------

    def extract_github_attributes(data)
      # Map API data to our attributes
      attrs = GITHUB_ATTRIBUTE_MAP.each_with_object({}) do |(our_key, api_path), result|
        value = api_path.is_a?(Array) ? data.dig(*api_path) : data[api_path]
        result[our_key] = value if value.present?
      end

      # Add attributes with defaults
      ATTRIBUTE_DEFAULTS.each do |key, default|
        api_key = key == :is_fork ? :fork : key
        attrs[key] = data[api_key] || default
      end

      # Add tracking fields
      attrs.merge!(
        last_fetched_at: Time.current,
        search_score: data[:score]
      )
    end
  end
end
