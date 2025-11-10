class AddEmbeddingToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :embedding, :jsonb
  end
end
