# Query object for comprehensive comparison search with relevance scoring
#
# Why raw SQL?
# - Uses PostgreSQL's pg_trgm WORD_SIMILARITY for fuzzy matching
# - Complex relevance scoring with field-specific weights
# - Synonym expansion with multiple terms
# - Subqueries for category matching with confidence scores
# - More efficient than building complex Arel expressions
#
# Returns: ActiveRecord::Relation of Comparison records with relevance_score attribute
#
# Usage:
#   # Direct usage
#   Comparison.search("background job", fuzzy: true)
#
#   # Can be chained with other scopes if needed
#   Comparison.cached.search("rails cache")
class ComparisonSearchQuery
  def self.call(search_term:, fuzzy: true, scope: Comparison.all)
    new(search_term:, fuzzy:, scope:).call
  end

  def initialize(search_term:, fuzzy:, scope: Comparison.all)
    @search_term = search_term
    @fuzzy = fuzzy
    @scope = scope
  end

  def call
    return scope if search_term.blank?

    scope
      .select("comparisons.*, #{relevance_score_sql} AS relevance_score")
      .where(conditions.join(" OR "))
      .order("relevance_score DESC, created_at DESC")
  end

  private

  attr_reader :search_term, :fuzzy, :scope

  def expanded_terms
    @expanded_terms ||= SearchSynonymExpander.expand(search_term)
  end

  def relevance_score_sql
    # Use GREATEST to get the maximum score across all synonym terms
    # This way, the best-matching synonym determines the relevance
    "GREATEST(#{score_expressions.map { |expr| "(#{expr})" }.join(', ')})"
  end

  def score_expressions
    # Build scoring expressions for each expanded term
    # Weights: user_query (100), technologies (50), problem_domains (30), architecture_patterns (20), categories (10)
    expanded_terms.map do |term|
      sanitized = Comparison.sanitize_sql_like(term)

      if fuzzy
        fuzzy_score_expression(sanitized)
      else
        exact_score_expression(sanitized)
      end
    end
  end

  def fuzzy_score_expression(sanitized)
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
  end

  def exact_score_expression(sanitized)
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

  def conditions
    # Build WHERE conditions for each expanded term
    expanded_terms.map do |term|
      sanitized = Comparison.sanitize_sql_like(term)

      if fuzzy
        fuzzy_condition(sanitized)
      else
        exact_condition(sanitized)
      end
    end
  end

  def fuzzy_condition(sanitized)
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
  end

  def exact_condition(sanitized)
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
