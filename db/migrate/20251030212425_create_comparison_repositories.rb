class CreateComparisonRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :comparison_repositories do |t|
      t.references :comparison, null: false, foreign_key: true
      t.references :repository, null: false, foreign_key: true
      t.integer :rank
      t.integer :score
      t.jsonb :pros, default: []
      t.jsonb :cons, default: []
      t.text :fit_reasoning

      t.timestamps
    end

    add_index :comparison_repositories, [:comparison_id, :rank]
  end
end
