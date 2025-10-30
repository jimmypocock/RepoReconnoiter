class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :category_type, null: false
      t.text :description
      t.integer :repositories_count, default: 0

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :category_type
    add_index :categories, [ :category_type, :repositories_count ]
  end
end
