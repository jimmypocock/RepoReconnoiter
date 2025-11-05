class Comparison < ApplicationRecord
  #--------------------------------------
  # CONFIGURATION
  #--------------------------------------

  # Similarity threshold for fuzzy query matching (0.0 - 1.0)
  # Higher = stricter matching, fewer cache hits
  # Lower = looser matching, more cache hits (but potential false positives)
  # REQUIRED: Set COMPARISON_SIMILARITY_THRESHOLD in .env (see .env.example)
  SIMILARITY_THRESHOLD = ENV.fetch("COMPARISON_SIMILARITY_THRESHOLD").to_f

  # Cache TTL in days - comparisons older than this are considered stale
  # REQUIRED: Set COMPARISON_CACHE_DAYS in .env (see .env.example)
  CACHE_TTL_DAYS = ENV.fetch("COMPARISON_CACHE_DAYS").to_i

  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  has_many :comparison_categories, dependent: :restrict_with_error
  has_many :categories, through: :comparison_categories
  has_many :comparison_repositories, dependent: :restrict_with_error
  has_many :repositories, through: :comparison_repositories

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :cost_usd, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :input_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :normalized_query, presence: true
  validates :output_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :user_query, presence: true, length: { minimum: 1, maximum: 500 }
  validates :view_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :user_query_not_blank

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_validation :normalize_query
  before_save :calculate_cost, if: -> { model_used.present? && input_tokens.present? && output_tokens.present? }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :by_problem_domain, ->(domain) { where(problem_domain: domain) }
  scope :cached, -> { where("created_at > ?", CACHE_TTL_DAYS.days.ago) }
  scope :popular, -> { order(view_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :stale, -> { where("created_at <= ?", CACHE_TTL_DAYS.days.ago) }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def cache_fresh?
    created_at > CACHE_TTL_DAYS.days.ago
  end

  def cache_stale?
    !cache_fresh?
  end

  def increment_view_count!
    increment!(:view_count)
  end

  def recommended_repository
    repositories.joins(:comparison_repositories)
      .where(comparison_repositories: { comparison_id: id })
      .order("comparison_repositories.rank ASC")
      .first
  end

  def total_tokens
    (input_tokens || 0) + (output_tokens || 0)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Find similar cached comparison using fuzzy matching
    # Returns: [comparison, similarity_score] or [nil, 0.0]
    def find_similar_cached(query)
      normalized = normalize_query_string(query)

      result = cached
        .select("comparisons.*, SIMILARITY(normalized_query, #{connection.quote(normalized)}) AS similarity_score")
        .where("SIMILARITY(normalized_query, ?) > ?", normalized, SIMILARITY_THRESHOLD)
        .order("similarity_score DESC, created_at DESC")
        .first

      return [ nil, 0.0 ] unless result

      # similarity_score is available as an attribute on the result
      [ result, result.similarity_score ]
    end

    # Normalize query string for consistent matching
    # Replicates: .strip.downcase.squish
    def normalize_query_string(query)
      query.to_s.strip.downcase.squish
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def calculate_cost
    rates = case model_used
    when "gpt-4o-mini"
      { input: 0.150 / 1_000_000, output: 0.600 / 1_000_000 }
    when "gpt-4o"
      { input: 2.50 / 1_000_000, output: 10.00 / 1_000_000 }
    else
      return
    end

    self.cost_usd = (input_tokens * rates[:input]) + (output_tokens * rates[:output])
  end

  def normalize_query
    self.normalized_query = self.class.normalize_query_string(user_query)
  end

  def user_query_not_blank
    if user_query.present? && user_query.strip.blank?
      errors.add(:user_query, "cannot be only whitespace")
    end
  end
end
