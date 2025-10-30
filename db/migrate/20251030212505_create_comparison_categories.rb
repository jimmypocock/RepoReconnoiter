class CreateComparisonCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :comparison_categories do |t|
      t.references :comparison, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :assigned_by, default: "inferred"

      t.timestamps
    end

    add_index :comparison_categories, [:comparison_id, :category_id], unique: true
  end
end
