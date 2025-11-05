class EnablePgTrgmForComparisons < ActiveRecord::Migration[8.1]
  def up
    # Enable PostgreSQL trigram extension for fuzzy string matching
    enable_extension 'pg_trgm'

    # Add normalized query column for fast similarity lookups
    add_column :comparisons, :normalized_query, :string

    # Backfill using pure SQL (single UPDATE query)
    # Replicates Ruby's: .strip.downcase.squish
    execute <<-SQL
      UPDATE comparisons
      SET normalized_query = LOWER(
        TRIM(
          REGEXP_REPLACE(user_query, E'\\\\s+', ' ', 'g')
        )
      )
      WHERE user_query IS NOT NULL
    SQL

    # GIN index for trigram similarity searches
    add_index :comparisons, :normalized_query,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: 'index_comparisons_on_normalized_query_trgm'
  end

  def down
    remove_index :comparisons, name: 'index_comparisons_on_normalized_query_trgm'
    remove_column :comparisons, :normalized_query
    disable_extension 'pg_trgm'
  end
end
