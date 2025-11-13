class CreateComparisonStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :comparison_statuses do |t|
      t.string :session_id, null: false
      t.string :status, null: false, default: "processing"
      t.references :comparison, null: true, foreign_key: true  # Nullable - set when completed
      t.references :user, null: false, foreign_key: true
      t.text :error_message

      t.timestamps
    end
    add_index :comparison_statuses, :session_id, unique: true
  end
end
