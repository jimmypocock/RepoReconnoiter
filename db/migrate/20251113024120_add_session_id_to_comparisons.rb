class AddSessionIdToComparisons < ActiveRecord::Migration[8.1]
  def change
    add_column :comparisons, :session_id, :string
    add_index :comparisons, :session_id, unique: true
    add_column :comparisons, :status, :string
  end
end
