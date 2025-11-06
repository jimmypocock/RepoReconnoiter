class AddUserToAiCosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :ai_costs, :user, null: true, foreign_key: true
  end
end
