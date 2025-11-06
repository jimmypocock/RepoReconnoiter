# Query object for fetching comparisons for homepage display
#
# Why raw SQL?
# - Uses PostgreSQL's DISTINCT ON for efficient deduplication
# - UNION for hybrid sorting (recent popular + all-time backfill)
# - Single query vs multiple queries with Ruby deduplication (more efficient)
#
# Returns: Array of Comparison records (unique by normalized_query)
#
# Usage:
#   HomepageComparisonsQuery.call(limit: 20, recent_days: 7)
class HomepageComparisonsQuery
  def self.call(limit: 20, recent_days: 7)
    new(limit: limit, recent_days: recent_days).call
  end

  def initialize(limit:, recent_days:)
    @limit = limit
    @recent_days = recent_days
  end

  def call
    Comparison.find_by_sql(sql)
  end

  private

  attr_reader :limit, :recent_days

  def cutoff_date
    recent_days.days.ago
  end

  def sql
    Comparison.sanitize_sql_array([
      <<-SQL.squish,
        SELECT DISTINCT ON (normalized_query) *
        FROM (
          (
            SELECT DISTINCT ON (normalized_query) *, 1 as sort_priority
            FROM comparisons
            WHERE created_at > ?
            ORDER BY normalized_query, view_count DESC, created_at DESC
          )
          UNION ALL
          (
            SELECT DISTINCT ON (normalized_query) *, 2 as sort_priority
            FROM comparisons
            ORDER BY normalized_query, view_count DESC
          )
        ) combined
        ORDER BY normalized_query, sort_priority, view_count DESC, created_at DESC
        LIMIT ?
      SQL
      cutoff_date,
      limit
    ])
  end
end
