class CreateQueuedAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :queued_analyses do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :analysis_type, null: false
      t.integer :priority, default: 0
      t.string :status, default: "pending"
      t.text :error_message
      t.datetime :scheduled_for
      t.integer :retry_count, default: 0
      t.datetime :processed_at

      t.timestamps
    end

    add_index :queued_analyses, [ :status, :priority, :scheduled_for ], name: "index_queued_analyses_processing"
    add_index :queued_analyses, :created_at
  end
end
