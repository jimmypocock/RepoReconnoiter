class CreateAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :analyses do |t|
      t.references :repository, null: false, foreign_key: true

      # Analysis metadata
      t.string :analysis_type, null: false
      t.string :model_used, null: false
      t.integer :input_tokens
      t.integer :output_tokens
      t.decimal :cost_usd, precision: 10, scale: 6

      # AI outputs - Tier 1 (Categorization)
      t.text :summary
      t.text :use_cases

      # AI outputs - Tier 2 (Deep Dive)
      t.text :why_care
      t.text :key_insights
      t.text :learning_value
      t.string :maturity_assessment
      t.jsonb :quality_signals

      # Caching and versioning
      t.string :content_hash
      t.datetime :expires_at
      t.boolean :is_current, default: true

      t.timestamps
    end

    add_index :analyses, [ :repository_id, :analysis_type, :is_current ], name: "index_analyses_current"
    add_index :analyses, :analysis_type
    add_index :analyses, :created_at
    add_index :analyses, :cost_usd
    add_index :analyses, :is_current
  end
end
