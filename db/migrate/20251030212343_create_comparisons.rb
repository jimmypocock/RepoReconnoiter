class CreateComparisons < ActiveRecord::Migration[8.1]
  def change
    create_table :comparisons do |t|
      t.text :user_query, null: false
      t.string :tech_stack
      t.string :problem_domain
      t.jsonb :constraints, default: []
      t.text :github_search_query
      t.string :recommended_repo_full_name
      t.text :recommendation_reasoning
      t.jsonb :ranking_results
      t.integer :repos_compared_count
      t.string :model_used
      t.integer :input_tokens
      t.integer :output_tokens
      t.decimal :cost_usd, precision: 10, scale: 6
      t.integer :view_count, default: 0

      t.timestamps
    end

    add_index :comparisons, :problem_domain
    add_index :comparisons, :view_count
    add_index :comparisons, :created_at
  end
end
