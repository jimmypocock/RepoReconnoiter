class RenameComparisonTechStackToTechnologiesAndAddGinIndexes < ActiveRecord::Migration[8.1]
  def change
    # Rename fields to plural to match their content (multiple values)
    # Column names are plural because they store comma-separated values
    # Category types remain singular (technology, problem_domain, architecture_pattern)
    rename_column :comparisons, :tech_stack, :technologies
    rename_column :comparisons, :problem_domain, :problem_domains

    # Add new architecture_patterns column to match category types
    add_column :comparisons, :architecture_patterns, :string

    # Add GIN trigram indexes for WORD_SIMILARITY search performance
    # These indexes dramatically speed up fuzzy text matching on larger datasets
    add_index :comparisons, :technologies,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_comparisons_on_technologies_trgm"

    add_index :comparisons, :problem_domains,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_comparisons_on_problem_domains_trgm"

    add_index :comparisons, :architecture_patterns,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_comparisons_on_architecture_patterns_trgm"
  end
end
