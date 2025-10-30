class CreateAiCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_costs do |t|
      t.date :date, null: false
      t.string :model_used, null: false
      t.integer :total_requests, default: 0
      t.bigint :total_input_tokens, default: 0
      t.bigint :total_output_tokens, default: 0
      t.decimal :total_cost_usd, precision: 10, scale: 2, default: 0

      t.timestamps
    end

    add_index :ai_costs, [ :date, :model_used ], unique: true
    add_index :ai_costs, :date
  end
end
