class UpdateCategorySlugUniqueness < ActiveRecord::Migration[8.1]
  def change
    # Remove the old global unique index on slug
    remove_index :categories, :slug

    # Add a new composite unique index scoped to category_type
    # This allows the same slug across different category types
    add_index :categories, [ :slug, :category_type ], unique: true
  end
end
