class IncreaseAiCostPrecision < ActiveRecord::Migration[8.1]
  def change
    # Change from precision: 10, scale: 2 to precision: 10, scale: 6
    # This allows tracking costs like $0.000150 (gpt-4o-mini queries)
    # instead of rounding everything to $0.00
    change_column :ai_costs, :total_cost_usd, :decimal, precision: 10, scale: 6, default: 0
  end
end
