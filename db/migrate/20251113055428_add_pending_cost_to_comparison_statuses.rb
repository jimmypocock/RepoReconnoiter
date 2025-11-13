class AddPendingCostToComparisonStatuses < ActiveRecord::Migration[8.1]
  def change
    add_column :comparison_statuses, :pending_cost_usd, :decimal, precision: 10, scale: 6, default: 0.0, null: false
  end
end
