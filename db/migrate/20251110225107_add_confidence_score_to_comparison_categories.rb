class AddConfidenceScoreToComparisonCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :comparison_categories, :confidence_score, :decimal, precision: 3, scale: 2
  end
end
