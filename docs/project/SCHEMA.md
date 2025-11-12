# Database Schema Design

Based on GitHub API exploration and OVERVIEW.md requirements.

## Design Principles

1. **Cache GitHub data** to minimize API calls and avoid rate limits
2. **Track AI analysis costs** to stay under budget ($10/month target)
3. **Smart cache invalidation** - only re-analyze when content changes
4. **Version AI analyses** - keep history, mark current with `is_current` flag
5. **JSONB for flexibility** - topics, quality signals, metrics (PostgreSQL-specific)

---

## MVP Tables (Phase 1-3)

These are the core tables needed for initial launch.

### 1. `repositories`

Stores GitHub repository data with smart caching.

```ruby
create_table :repositories do |t|
  # GitHub identifiers
  t.bigint :github_id, null: false              # Numeric ID from API
  t.string :node_id, null: false                # Node ID (more stable)
  t.string :full_name, null: false              # "owner/repo"
  t.string :name, null: false                   # "repo"

  # Basic metadata
  t.text :description
  t.string :html_url, null: false
  t.string :homepage_url
  t.string :clone_url

  # Owner info (denormalized for display)
  t.string :owner_login
  t.string :owner_avatar_url
  t.string :owner_type                          # "User" or "Organization"

  # Repository stats (updated on each fetch)
  t.integer :stargazers_count, default: 0
  t.integer :forks_count, default: 0
  t.integer :open_issues_count, default: 0
  t.integer :watchers_count, default: 0
  t.integer :size                               # Repo size in KB

  # Technical metadata
  t.string :language                            # Primary language
  t.jsonb :topics, default: []                  # GitHub topics/tags
  t.string :license                             # License key (e.g., "mit")
  t.string :default_branch, default: "main"

  # Repository properties
  t.boolean :is_fork, default: false
  t.boolean :is_template, default: false
  t.boolean :archived, default: false
  t.boolean :disabled, default: false
  t.string :visibility, default: "public"       # "public", "private", "internal"

  # GitHub timestamps
  t.datetime :github_created_at
  t.datetime :github_updated_at
  t.datetime :github_pushed_at

  # Cached README content
  t.text :readme_content                        # Cached HTML README
  t.string :readme_sha                          # SHA to detect changes
  t.integer :readme_length
  t.datetime :readme_fetched_at

  # Our tracking metadata
  t.datetime :last_fetched_at
  t.datetime :last_analyzed_at
  t.integer :fetch_count, default: 0
  t.float :search_score                         # GitHub search relevance score

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
add_index :repositories, [:archived, :disabled]
add_index :repositories, :topics, using: :gin   # JSONB index for topic searches
```

**Key Changes from OVERVIEW.md:**

- Added `node_id` (GitHub's stable string identifier)
- Added owner fields for display (owner_login, owner_avatar_url)
- Removed `language_breakdown` (requires extra API call - defer to later)
- Added `is_fork`, `is_template`, `archived`, `disabled`, `visibility` (all available in API)
- Added `search_score` from GitHub search results
- Added `readme_fetched_at` to track README caching separately

---

### 2. `categories`

Categorization taxonomy (seeded from OVERVIEW.md categories).

```ruby
create_table :categories do |t|
  t.string :name, null: false                   # "Authentication & Identity"
  t.string :slug, null: false                   # "authentication-identity"
  t.string :category_type, null: false          # "problem_domain", "architecture_pattern", "maturity"
  t.text :description
  t.integer :repositories_count, default: 0    # Counter cache

  t.timestamps
end

add_index :categories, :slug, unique: true
add_index :categories, :category_type
add_index :categories, [:category_type, :repositories_count]
```

**Category Types:**

- `problem_domain`: What problem it solves (Authentication, Data Sync, Rate Limiting, etc.)
- `architecture_pattern`: How it's built (Microservices, Event-driven, Serverless, etc.)
- `maturity`: Production readiness (Experimental, Active Development, Production Ready, etc.)

---

### 3. `repository_categories`

Join table linking repositories to categories (many-to-many).

```ruby
create_table :repository_categories do |t|
  t.references :repository, null: false, foreign_key: true
  t.references :category, null: false, foreign_key: true
  t.float :confidence_score                     # AI confidence (0.0-1.0)
  t.string :assigned_by, default: "ai"          # "ai", "manual", "github_topics"

  t.timestamps
end

add_index :repository_categories, [:repository_id, :category_id],
  unique: true, name: "index_repo_categories_uniqueness"
add_index :repository_categories, :category_id
add_index :repository_categories, :confidence_score
```

**Purpose:**

- Track which categories apply to each repo
- Store AI confidence for debugging/quality control
- Allow manual overrides (assigned_by: "manual")

---

### 4. `ai_analyses`

Versioned AI-generated insights with cost tracking.

```ruby
create_table :ai_analyses do |t|
  t.references :repository, null: false, foreign_key: true

  # Analysis metadata
  t.string :analysis_type, null: false          # "tier1_categorization", "tier2_deep_dive"
  t.string :model_used, null: false             # "gpt-5-mini", "gpt-5"
  t.integer :input_tokens
  t.integer :output_tokens
  t.decimal :cost_usd, precision: 10, scale: 6

  # AI outputs - Tier 1 (Categorization)
  t.text :summary                               # One-line description
  t.text :use_cases                             # What problems it solves

  # AI outputs - Tier 2 (Deep Dive)
  t.text :why_care                              # Why developer should care
  t.text :key_insights                          # Insights from README + issues
  t.text :learning_value                        # What you'd learn from this code
  t.string :maturity_assessment                 # "experimental", "production_ready", etc.
  t.jsonb :quality_signals                      # Extracted from issues analysis

  # Caching and versioning
  t.string :content_hash                        # Hash of README + issues analyzed
  t.datetime :expires_at                        # When to refresh
  t.boolean :is_current, default: true          # Only one current per repo + type

  t.timestamps
end

add_index :ai_analyses, [:repository_id, :analysis_type, :is_current],
  name: "index_ai_analyses_current"
add_index :ai_analyses, :analysis_type
add_index :ai_analyses, :created_at
add_index :ai_analyses, :cost_usd
add_index :ai_analyses, :is_current
```

**Key Design:**

- Separate analysis_type for Tier 1 (cheap categorization) vs Tier 2 (expensive deep dive)
- Version history: keep old analyses, mark latest as `is_current`
- Track every penny: input_tokens, output_tokens, cost_usd
- content_hash to detect when re-analysis is needed

---

### 5. `analysis_queue`

Queue for batch processing AI analysis jobs.

```ruby
create_table :analysis_queue do |t|
  t.references :repository, null: false, foreign_key: true
  t.string :analysis_type, null: false          # "tier1_categorization", "tier2_deep_dive"
  t.integer :priority, default: 0               # Higher = more urgent
  t.string :status, default: "pending"          # "pending", "processing", "completed", "failed"
  t.text :error_message
  t.datetime :scheduled_for
  t.integer :retry_count, default: 0
  t.datetime :processed_at

  t.timestamps
end

add_index :analysis_queue, [:status, :priority, :scheduled_for],
  name: "index_analysis_queue_processing"
add_index :analysis_queue, :repository_id
add_index :analysis_queue, :created_at
```

**Purpose:**

- Batch process AI analysis to control costs
- Priority queue: trending repos analyzed first
- Retry logic for failures

---

### 6. `ai_spend`

Daily rollup of AI API spending.

```ruby
create_table :ai_spend do |t|
  t.date :date, null: false
  t.string :model_used, null: false             # "gpt-5-mini", "gpt-5"
  t.integer :total_requests, default: 0
  t.bigint :total_input_tokens, default: 0
  t.bigint :total_output_tokens, default: 0
  t.decimal :total_cost_usd, precision: 10, scale: 2, default: 0

  t.timestamps
end

add_index :ai_spend, [:date, :model_used], unique: true
add_index :ai_spend, :date
```

**Purpose:**

- Monitor daily spending to stay under budget
- Alert when approaching $10/month limit
- Track which models cost the most

---

### 7. `github_issues` (Phase 3)

Cache recent issues for Tier 2 analysis. **Optional for MVP - can defer to Phase 3.**

```ruby
create_table :github_issues do |t|
  t.references :repository, null: false, foreign_key: true
  t.bigint :github_issue_id, null: false
  t.integer :github_number, null: false         # Issue number (#123)
  t.string :title
  t.text :body
  t.string :state                               # "open", "closed"
  t.integer :comments_count, default: 0
  t.jsonb :labels, default: []
  t.datetime :github_created_at
  t.datetime :github_updated_at

  # AI analysis (from Tier 2)
  t.string :issue_type                          # "bug", "feature", "question"
  t.string :severity                            # "critical", "major", "minor"
  t.boolean :analyzed, default: false

  t.timestamps
end

add_index :github_issues, [:repository_id, :github_issue_id],
  unique: true, name: "index_github_issues_uniqueness"
add_index :github_issues, :state
add_index :github_issues, :analyzed
add_index :github_issues, :github_created_at
```

---

## Post-MVP Tables (Phase 4+)

These can be added after initial launch when we add user authentication and advanced features.

### 8. `users` (Future)

User accounts for personalization.

```ruby
create_table :users do |t|
  t.string :email
  t.string :github_username
  t.string :github_uid                          # OAuth identifier

  # Preferences
  t.jsonb :tech_stack, default: []              # ["Rails", "PostgreSQL", "React"]
  t.jsonb :interests, default: []               # ["machine-learning", "devops"]
  t.string :experience_level                    # "beginner", "intermediate", "advanced"

  # Feature flags
  t.boolean :weekly_digest_enabled, default: true
  t.integer :free_deep_dives_remaining, default: 3
  t.string :subscription_tier, default: "free"  # "free", "pro"

  t.timestamps
end

add_index :users, :email, unique: true
add_index :users, :github_username
```

---

### 9. `user_repository_interactions` (Future)

Track user bookmarks and interactions.

```ruby
create_table :user_repository_interactions do |t|
  t.references :user, null: false, foreign_key: true
  t.references :repository, null: false, foreign_key: true
  t.string :interaction_type                    # "viewed", "bookmarked", "dismissed"
  t.text :notes

  t.timestamps
end

add_index :user_repository_interactions,
  [:user_id, :repository_id, :interaction_type],
  unique: true, name: "index_user_repo_interactions"
```

---

### 10. `trends` (Future)

Aggregate trend data for pattern detection.

```ruby
create_table :trends do |t|
  t.date :period_start
  t.date :period_end
  t.string :trend_type                          # "rising_tech", "declining_tech", "new_pattern"
  t.string :name                                # "Vector Databases"
  t.text :description
  t.jsonb :metrics                              # Growth %, repo count, etc.
  t.jsonb :example_repos                        # Array of repo IDs

  t.timestamps
end

add_index :trends, [:period_start, :trend_type]
add_index :trends, :trend_type
```

---

## Summary: Migration Order

### MVP (Phases 1-3)

1. ✅ `repositories` - Core GitHub data
2. ✅ `categories` - Categorization taxonomy
3. ✅ `repository_categories` - Join table
4. ✅ `ai_analyses` - AI insights with cost tracking
5. ✅ `analysis_queue` - Batch processing queue
6. ✅ `ai_spend` - Daily spending rollup
7. 🔶 `github_issues` - Optional for Phase 3 (Tier 2 deep dives)

### Post-MVP (Phase 4+)

8. 🚫 `users` - Add when implementing auth
9. 🚫 `user_repository_interactions` - Add with users
10. 🚫 `trends` - Add for trend analysis features

---

## Key Differences from OVERVIEW.md

1. **Added fields from actual API**: `node_id`, `owner_login`, `owner_avatar_url`, `search_score`, `is_fork`, `is_template`, `archived`, `disabled`, `visibility`
2. **Removed premature optimizations**: `language_breakdown` (requires extra API call)
3. **Deferred user features**: `users` and `user_repository_interactions` moved to post-MVP
4. **Deferred trend analysis**: `trends` moved to post-MVP
5. **Simplified analysis types**: Using "tier1_categorization" and "tier2_deep_dive" instead of multiple analysis types
6. **Better GitHub issue tracking**: Added `github_number` field for issue references

---

## Next Steps

1. Create migrations for MVP tables (1-6)
2. Optionally include `github_issues` if we want it in Phase 3
3. Create corresponding models with validations
4. Seed initial categories from OVERVIEW.md
