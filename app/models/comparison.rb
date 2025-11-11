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

  belongs_to :user, optional: true
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

  scope :cached, -> { where("created_at > ?", CACHE_TTL_DAYS.days.ago) }
  scope :popular, -> { order(view_count: :desc) }
  scope :this_month, -> { where("created_at > ?", 30.days.ago) }
  scope :this_week, -> { where("created_at > ?", 7.days.ago) }

  # Comprehensive search across all relevant comparison fields and associated categories
  # Searches: user_query, technologies, problem_domains, architecture_patterns, and category names
  # Includes synonym expansion, fuzzy matching via pg_trgm, and relevance scoring
  # @param search_term [String] The search term to match (case-insensitive)
  # @param fuzzy [Boolean] Use fuzzy word_similarity matching (default: true)
  scope :search, ->(search_term, fuzzy: true) {
    return all if search_term.blank?

    # Expand search term to include synonyms
    expanded_terms = SearchSynonymExpander.expand(search_term)

    # Build scoring expressions for each expanded term
    # Weights: user_query (100), technologies (50), problem_domains (30), architecture_patterns (20), categories (10)
    score_expressions = expanded_terms.map do |term|
      sanitized = sanitize_sql_like(term)

      if fuzzy
        # Use WORD_SIMILARITY scores multiplied by field weights
        <<~SQL.squish
          WORD_SIMILARITY('#{sanitized}', user_query) * 100 +
          WORD_SIMILARITY('#{sanitized}', COALESCE(technologies, '')) * 50 +
          WORD_SIMILARITY('#{sanitized}', COALESCE(problem_domains, '')) * 30 +
          WORD_SIMILARITY('#{sanitized}', COALESCE(architecture_patterns, '')) * 20 +
          COALESCE((
            SELECT MAX(WORD_SIMILARITY('#{sanitized}', c.name) * 10 * COALESCE(cc.confidence_score, 0.5))
            FROM comparison_categories cc
            JOIN categories c ON c.id = cc.category_id
            WHERE cc.comparison_id = comparisons.id
            AND WORD_SIMILARITY('#{sanitized}', c.name) > 0.45
          ), 0)
        SQL
      else
        # Use binary scoring (match = weight, no match = 0)
        <<~SQL.squish
          (CASE WHEN user_query ILIKE '%#{sanitized}%' THEN 100 ELSE 0 END) +
          (CASE WHEN technologies ILIKE '%#{sanitized}%' THEN 50 ELSE 0 END) +
          (CASE WHEN problem_domains ILIKE '%#{sanitized}%' THEN 30 ELSE 0 END) +
          (CASE WHEN architecture_patterns ILIKE '%#{sanitized}%' THEN 20 ELSE 0 END) +
          COALESCE((
            SELECT MAX(10 * COALESCE(cc.confidence_score, 0.5))
            FROM comparison_categories cc
            JOIN categories c ON c.id = cc.category_id
            WHERE cc.comparison_id = comparisons.id
            AND c.name ILIKE '%#{sanitized}%'
          ), 0)
        SQL
      end
    end

    # Use GREATEST to get the maximum score across all synonym terms
    # This way, the best-matching synonym determines the relevance
    # Wrap each expression in parentheses for proper precedence
    relevance_score_sql = "GREATEST(#{score_expressions.map { |expr| "(#{expr})" }.join(', ')})"

    # Build WHERE conditions (keep existing threshold logic for fuzzy matching)
    conditions = expanded_terms.map do |term|
      sanitized = sanitize_sql_like(term)

      if fuzzy
        <<~SQL.squish
          (
            WORD_SIMILARITY('#{sanitized}', user_query) > 0.45 OR
            WORD_SIMILARITY('#{sanitized}', COALESCE(technologies, '')) > 0.45 OR
            WORD_SIMILARITY('#{sanitized}', COALESCE(problem_domains, '')) > 0.45 OR
            WORD_SIMILARITY('#{sanitized}', COALESCE(architecture_patterns, '')) > 0.45 OR
            EXISTS (
              SELECT 1 FROM comparison_categories cc
              JOIN categories c ON c.id = cc.category_id
              WHERE cc.comparison_id = comparisons.id
              AND WORD_SIMILARITY('#{sanitized}', c.name) > 0.45
              AND COALESCE(cc.confidence_score, 0.5) >= 0.3
            )
          )
        SQL
      else
        <<~SQL.squish
          (
            user_query ILIKE '%#{sanitized}%' OR
            technologies ILIKE '%#{sanitized}%' OR
            problem_domains ILIKE '%#{sanitized}%' OR
            architecture_patterns ILIKE '%#{sanitized}%' OR
            EXISTS (
              SELECT 1 FROM comparison_categories cc
              JOIN categories c ON c.id = cc.category_id
              WHERE cc.comparison_id = comparisons.id
              AND c.name ILIKE '%#{sanitized}%'
              AND COALESCE(cc.confidence_score, 0.5) >= 0.3
            )
          )
        SQL
      end
    end

    # Select with relevance score, filter by conditions, order by score DESC
    select("comparisons.*, #{relevance_score_sql} AS relevance_score")
      .where(conditions.join(" OR "))
      .order("relevance_score DESC, created_at DESC")
  }

  # Fuzzy match against normalized_query using PostgreSQL's pg_trgm SIMILARITY function
  # Returns records with similarity_score attribute ordered by best match first
  # @param query [String] The query string to match against
  # @param threshold [Float] Minimum similarity score (0.0-1.0)
  scope :with_similarity_to, ->(query, threshold) {
    normalized = normalize_query_string(query)
    select("comparisons.*, SIMILARITY(normalized_query, #{connection.quote(normalized)}) AS similarity_score")
      .where("SIMILARITY(normalized_query, ?) > ?", normalized, threshold)
      .order("similarity_score DESC, created_at DESC")
  }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def increment_view_count!
    increment!(:view_count)
  end

  def recommended_repository
    comparison_repositories.order(:rank).first&.repository
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Fetch comparisons for homepage display with hybrid sorting
    # Returns up to 20 unique comparisons (recent popular + all-time backfill)
    # Delegates to HomepageComparisonsQuery for complex SQL logic
    def for_homepage(limit: 20, recent_days: 7)
      HomepageComparisonsQuery.call(limit:, recent_days:)
    end

    # Find similar cached comparison using fuzzy matching
    # Uses PostgreSQL's pg_trgm SIMILARITY() for fuzzy text matching
    # Returns: [comparison, similarity_score] or [nil, 0.0]
    def find_similar_cached(query)
      result = cached.with_similarity_to(query, SIMILARITY_THRESHOLD).first
      return [ nil, 0.0 ] unless result

      # similarity_score is available as an attribute added by with_similarity_to scope
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
    self.cost_usd = OpenAi.calculate_cost(
      input_tokens:,
      model: model_used,
      output_tokens:
    )
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
