class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      # GitHub identifiers
      t.bigint :github_id, null: false
      t.string :node_id, null: false
      t.string :full_name, null: false
      t.string :name, null: false

      # Basic metadata
      t.text :description
      t.string :html_url, null: false
      t.string :homepage_url
      t.string :clone_url

      # Owner info (denormalized for display)
      t.string :owner_login
      t.string :owner_avatar_url
      t.string :owner_type

      # Repository stats (updated on each fetch)
      t.integer :stargazers_count, default: 0
      t.integer :forks_count, default: 0
      t.integer :open_issues_count, default: 0
      t.integer :watchers_count, default: 0
      t.integer :size

      # Technical metadata
      t.string :language
      t.jsonb :topics, default: []
      t.string :license
      t.string :default_branch, default: "main"

      # Repository properties
      t.boolean :is_fork, default: false
      t.boolean :is_template, default: false
      t.boolean :archived, default: false
      t.boolean :disabled, default: false
      t.string :visibility, default: "public"

      # GitHub timestamps
      t.datetime :github_created_at
      t.datetime :github_updated_at
      t.datetime :github_pushed_at

      # Cached README content
      t.text :readme_content
      t.string :readme_sha
      t.integer :readme_length
      t.datetime :readme_fetched_at

      # Our tracking metadata
      t.datetime :last_fetched_at
      t.datetime :last_analyzed_at
      t.integer :fetch_count, default: 0
      t.float :search_score

      t.timestamps
    end

    # Indexes for common queries
    add_index :repositories, :github_id, unique: true
    add_index :repositories, :node_id, unique: true
    add_index :repositories, :full_name, unique: true
    add_index :repositories, :language
    add_index :repositories, :github_pushed_at
    add_index :repositories, :github_created_at
    add_index :repositories, :stargazers_count
    add_index :repositories, :last_analyzed_at
    add_index :repositories, [ :archived, :disabled ]
    add_index :repositories, :topics, using: :gin
  end
end
