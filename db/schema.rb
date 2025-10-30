# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_10_30_184311) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_costs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "model_used", null: false
    t.decimal "total_cost_usd", precision: 10, scale: 2, default: "0.0"
    t.bigint "total_input_tokens", default: 0
    t.bigint "total_output_tokens", default: 0
    t.integer "total_requests", default: 0
    t.datetime "updated_at", null: false
    t.index ["date", "model_used"], name: "index_ai_costs_on_date_and_model_used", unique: true
    t.index ["date"], name: "index_ai_costs_on_date"
  end

  create_table "analyses", force: :cascade do |t|
    t.string "analysis_type", null: false
    t.string "content_hash"
    t.decimal "cost_usd", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "input_tokens"
    t.boolean "is_current", default: true
    t.text "key_insights"
    t.text "learning_value"
    t.string "maturity_assessment"
    t.string "model_used", null: false
    t.integer "output_tokens"
    t.jsonb "quality_signals"
    t.bigint "repository_id", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.text "use_cases"
    t.text "why_care"
    t.index ["analysis_type"], name: "index_analyses_on_analysis_type"
    t.index ["cost_usd"], name: "index_analyses_on_cost_usd"
    t.index ["created_at"], name: "index_analyses_on_created_at"
    t.index ["is_current"], name: "index_analyses_on_is_current"
    t.index ["repository_id", "analysis_type", "is_current"], name: "index_analyses_current"
    t.index ["repository_id"], name: "index_analyses_on_repository_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "repositories_count", default: 0
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["category_type", "repositories_count"], name: "index_categories_on_category_type_and_repositories_count"
    t.index ["category_type"], name: "index_categories_on_category_type"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "queued_analyses", force: :cascade do |t|
    t.string "analysis_type", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "priority", default: 0
    t.datetime "processed_at"
    t.bigint "repository_id", null: false
    t.integer "retry_count", default: 0
    t.datetime "scheduled_for"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_queued_analyses_on_created_at"
    t.index ["repository_id"], name: "index_queued_analyses_on_repository_id"
    t.index ["status", "priority", "scheduled_for"], name: "index_queued_analyses_processing"
  end

  create_table "repositories", force: :cascade do |t|
    t.boolean "archived", default: false
    t.string "clone_url"
    t.datetime "created_at", null: false
    t.string "default_branch", default: "main"
    t.text "description"
    t.boolean "disabled", default: false
    t.integer "fetch_count", default: 0
    t.integer "forks_count", default: 0
    t.string "full_name", null: false
    t.datetime "github_created_at"
    t.bigint "github_id", null: false
    t.datetime "github_pushed_at"
    t.datetime "github_updated_at"
    t.string "homepage_url"
    t.string "html_url", null: false
    t.boolean "is_fork", default: false
    t.boolean "is_template", default: false
    t.string "language"
    t.datetime "last_analyzed_at"
    t.datetime "last_fetched_at"
    t.string "license"
    t.string "name", null: false
    t.string "node_id", null: false
    t.integer "open_issues_count", default: 0
    t.string "owner_avatar_url"
    t.string "owner_login"
    t.string "owner_type"
    t.text "readme_content"
    t.datetime "readme_fetched_at"
    t.integer "readme_length"
    t.string "readme_sha"
    t.float "search_score"
    t.integer "size"
    t.integer "stargazers_count", default: 0
    t.jsonb "topics", default: []
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public"
    t.integer "watchers_count", default: 0
    t.index ["archived", "disabled"], name: "index_repositories_on_archived_and_disabled"
    t.index ["full_name"], name: "index_repositories_on_full_name", unique: true
    t.index ["github_created_at"], name: "index_repositories_on_github_created_at"
    t.index ["github_id"], name: "index_repositories_on_github_id", unique: true
    t.index ["github_pushed_at"], name: "index_repositories_on_github_pushed_at"
    t.index ["language"], name: "index_repositories_on_language"
    t.index ["last_analyzed_at"], name: "index_repositories_on_last_analyzed_at"
    t.index ["node_id"], name: "index_repositories_on_node_id", unique: true
    t.index ["stargazers_count"], name: "index_repositories_on_stargazers_count"
    t.index ["topics"], name: "index_repositories_on_topics", using: :gin
  end

  create_table "repository_categories", force: :cascade do |t|
    t.string "assigned_by", default: "ai"
    t.bigint "category_id", null: false
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.bigint "repository_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_repository_categories_on_category_id"
    t.index ["confidence_score"], name: "index_repository_categories_on_confidence_score"
    t.index ["repository_id", "category_id"], name: "index_repo_categories_uniqueness", unique: true
    t.index ["repository_id"], name: "index_repository_categories_on_repository_id"
  end

  add_foreign_key "analyses", "repositories"
  add_foreign_key "queued_analyses", "repositories"
  add_foreign_key "repository_categories", "categories"
  add_foreign_key "repository_categories", "repositories"
end
