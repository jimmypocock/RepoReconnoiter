# Query object for fuzzy matching against normalized_query using pg_trgm SIMILARITY
#
# Why raw SQL?
# - Uses PostgreSQL's pg_trgm SIMILARITY function for fuzzy text matching
# - Returns similarity_score as a computed attribute for sorting/filtering
# - More efficient than multiple AR queries
#
# Returns: Lambda that can be chained with other scopes (e.g., .cached.with_similarity_to)
#
# Usage:
#   # Direct usage
#   Comparison.with_similarity_to("rails background job", 0.8)
#
#   # Chained with other scopes
#   Comparison.cached.with_similarity_to("rails background job", 0.8)
class ComparisonSimilarityQuery
  def self.call(query:, threshold:, scope: Comparison.all)
    new(query:, threshold:, scope:).call
  end

  def initialize(query:, threshold:, scope: Comparison.all)
    @query = query
    @threshold = threshold
    @scope = scope
  end

  def call
    normalized = Comparison.normalize_query_string(query)

    scope
      .select("comparisons.*, SIMILARITY(normalized_query, #{Comparison.connection.quote(normalized)}) AS similarity_score")
      .where("SIMILARITY(normalized_query, ?) > ?", normalized, threshold)
      .order("similarity_score DESC, created_at DESC")
  end

  private

  attr_reader :query, :threshold, :scope
end
