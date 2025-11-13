class CreateAnalysisStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :analysis_statuses do |t|
      t.string :session_id
      t.string :status
      t.references :user, null: false, foreign_key: true
      t.references :repository, null: true, foreign_key: true  # Nullable until analysis completes
      t.text :error_message

      t.timestamps
    end
    add_index :analysis_statuses, :session_id, unique: true
  end
end
