class ConvertAnalysesToSti < ActiveRecord::Migration[8.1]
  def up
    # Rename analysis_type to type for Rails STI convention
    rename_column :analyses, :analysis_type, :type

    # Update existing records to use class names
    # tier1_categorization -> Analysis (base class)
    # tier2_deep_dive -> AnalysisDeep (STI child class)
    execute <<-SQL
      UPDATE analyses
      SET type = CASE type
        WHEN 'tier1_categorization' THEN 'Analysis'
        WHEN 'tier2_deep_dive' THEN 'AnalysisDeep'
        ELSE type
      END
    SQL

    # Add deep-specific columns for AnalysisDeep
    add_column :analyses, :adoption_analysis, :text
    add_column :analyses, :issues_analysis, :text
    add_column :analyses, :maintenance_analysis, :text
    add_column :analyses, :readme_analysis, :text
    add_column :analyses, :security_analysis, :text

    # Update composite index to use new column name
    # (Single column index is automatically handled by rename_column)
    remove_index :analyses, name: "index_analyses_current"
    add_index :analyses, [ :repository_id, :type, :is_current ], name: "index_analyses_current"
  end

  def down
    # Remove deep-specific columns
    remove_column :analyses, :adoption_analysis
    remove_column :analyses, :issues_analysis
    remove_column :analyses, :maintenance_analysis
    remove_column :analyses, :readme_analysis
    remove_column :analyses, :security_analysis

    # Update composite index back
    # (Single column index is automatically handled by rename_column)
    remove_index :analyses, name: "index_analyses_current"

    # Revert class names to original values
    execute <<-SQL
      UPDATE analyses
      SET type = CASE type
        WHEN 'Analysis' THEN 'tier1_categorization'
        WHEN 'AnalysisDeep' THEN 'tier2_deep_dive'
        ELSE type
      END
    SQL

    # Rename back
    rename_column :analyses, :type, :analysis_type

    # Restore composite index
    # (Single column index is automatically handled by rename_column)
    add_index :analyses, [ :repository_id, :analysis_type, :is_current ], name: "index_analyses_current"
  end
end
