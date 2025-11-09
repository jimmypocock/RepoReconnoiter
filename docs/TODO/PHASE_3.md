# Phase 3: AI Integration (Tier 1 Categorization + Tier 3 Comparative Evaluation)

**Note**: Tier 2 (Deep Analysis) was deferred to post-MVP. See `docs/TODO/FUTURE.md` for details.

---

# Phase 3.5: AI Integration - Tier 3 (Comparative Evaluation) ✅ COMPLETE

**Use Case**: Junior devs (or anyone) needs to evaluate multiple libraries/tools for a specific need.

**Example Queries:**

- _"I need a Rails background job library with retry logic and monitoring"_
- _"Looking for a Python authentication system that supports OAuth and 2FA"_
- _"Need a React state management library for large applications"_

**Cost per Comparison**: ~$0.045 (220 comparisons per $10 budget)

- Step 1 (Parse): gpt-4o-mini ~$0.0003
- Step 3 (Compare): gpt-4o ~$0.045

## Database Schema

- [x] Create `comparisons` table
  - `user_query` (text) - Original user input
  - `tech_stack`, `problem_domain` (string) - Extracted from query
  - `constraints` (jsonb) - Array of requirements ["retry logic", "monitoring"]
  - `github_search_query` (text) - Generated search string
  - `recommended_repo_full_name` (string) - Top recommendation
  - `recommendation_reasoning` (text) - Why this one?
  - `ranking_results` (jsonb) - Full AI comparison response
  - `repos_compared_count` (integer)
  - `model_used`, `input_tokens`, `output_tokens`, `cost_usd`
  - `view_count` (integer) - Track popularity
  - Timestamps
- [x] Create `comparison_repositories` join table
  - Links Comparison to Repository (many-to-many)
  - `rank` (integer) - Position in ranking (1-5)
  - `score` (integer) - AI score 0-100
  - `pros` (jsonb) - Array of strengths
  - `cons` (jsonb) - Array of weaknesses
  - `fit_reasoning` (text) - Why this fits user's needs
- [x] Create `comparison_categories` join table
  - Links Comparison to Category (many-to-many)
  - `assigned_by` (string) - "ai" or "inferred"
  - Enables browsing comparisons by category
- [x] Create models: `Comparison`, `ComparisonRepository`, `ComparisonCategory`
- [x] Update `Repository` and `Category` models with comparison associations

## Step 1: Query Parser Service (gpt-4o-mini) ✅ COMPLETE

- [x] Renamed from `QueryParserService` to `UserQueryParser` (follows "Doer" naming pattern)
- [x] Parse natural language into structured data
  - [x] Extract tech stack (Rails, Python, React, etc.) - or null for language-agnostic
  - [x] Extract problem domain (background jobs, authentication, monitoring, etc.)
  - [x] Extract constraints/requirements as array
  - [x] Generate GitHub search query string(s)
- [x] Return validation status (enough info to proceed?)
- [x] ✅ **MULTI-QUERY STRATEGY IMPLEMENTED**
  - [x] ✅ Updated response format: `github_queries` (array) + `query_strategy` field
  - [x] ✅ Single-query scenarios work (Rails, React, Python)
  - [x] ✅ Multi-query for edge cases (Python ORMs, Node.js frameworks, JS/TS testing)
  - [x] ✅ Multi-query when user mentions specific services (Stripe, PayPal, OAuth, Redis)
  - [x] ✅ Backend frameworks use language filter only (Rails → `language:ruby`)
  - [x] ✅ Frontend frameworks use TypeScript for modern libs (React → `language:typescript`)
  - [x] ✅ Infrastructure/DevOps queries use NO language filter (docker, monitoring, search engines)
  - [x] ✅ Universal `stars:>100` threshold validated across all ecosystems
  - [x] ✅ Tested: Python ORM returns 2 queries, Node.js returns 2 queries, JS testing returns 2 queries
  - [x] ✅ Language-agnostic queries work (charting, docker, monitoring, search engines, desktop apps)
- [x] **COMPREHENSIVE TESTING INFRASTRUCTURE**
  - [x] Created `analyze:test_suite` - Runs 30 diverse queries holistically with statistics
  - [x] Created `analyze:compare` - Test single query through full pipeline (parse → search → merge)
  - [x] Created `analyze:validate_queries` - Test suite with expected repos validation
  - [x] Created `analyze:repo` - Test Tier 1 analysis on single repository
  - [x] All tasks use environment variables (QUERY= and REPO=) - no escaping needed
  - [x] All tasks show helpful usage instructions when run without arguments
  - [x] ✅ **100% success rate** on 30-query test suite (was 83.3%, now 100%)
- [x] **PROMPT OPTIMIZATION**
  - [x] Accept language-agnostic queries for infrastructure/DevOps tools
  - [x] Principle-based rules instead of infinite examples
  - [x] Only reject truly meaningless queries ("best library", "good tool")
  - [x] Let GitHub's relevance ranking work - don't be too opinionated
- [x] **COST TRACKING IMPROVEMENTS**
  - [x] Created `OpenAi` service wrapper with automatic cost tracking
  - [x] Model whitelisting (gpt-4o-mini, gpt-4o) with explicit pricing
  - [x] Updated `ai_costs` table precision from 2 to 6 decimal places (tracks $0.000150 costs)
  - [x] All AI calls automatically tracked to daily rollup table
- [x] Cost: ~1200 tokens = $0.0003 per parse

**Testing Notes** (Phase 1 GitHub Search Research):

- GitHub search API quirks discovered:
  - Different libraries use different terminology (Sidekiq="processing", Resque="jobs")
  - Simpler queries (1-2 keywords) work better than complex ones
  - `in:name,description` filters are too restrictive - removed
  - Can't get ALL relevant libraries in one query - multi-query strategy solves this!
- Successful query patterns:
  - Backend: `"background processing language:ruby stars:>100"` (14 results, Sidekiq #1)
  - Backend: `"authentication language:python stars:>100"` (224 results, authentik/django-allauth top)
  - Frontend: `"state management language:typescript stars:>100"` (returns Redux, Zustand, MobX)
  - Multi-query: Python ORMs need both "orm" and "sqlalchemy" queries to be comprehensive
  - Multi-query: Node.js needs both JavaScript and TypeScript queries
  - See `GITHUB_SEARCH_RESEARCH.md` for full 16 golden queries documentation

## Step 2: Fetch & Prepare Repos ✅ COMPLETE

- [x] Execute GitHub search with generated query (multi-query support)
- [x] Fetch top N repos (default 10, configurable via limit parameter)
- [x] Filter out archived/disabled repos (tracked in quality signals)
- [x] Check which repos need Tier 1 analysis (`Repository#needs_analysis?`)
- [x] Auto-trigger Tier 1 for unanalyzed repos (synchronous execution)
- [x] Wait for all analyses to complete before comparison (synchronous by design)
- [x] Collect GitHub quality signals for each repo:
  - Last commit date (`github_pushed_at`)
  - Open issues count
  - Stars vs age (growth velocity / `stars_per_day`)
  - Fork count (community adoption)
  - Archived/disabled status
- [x] Created `RepositoryFetcher` service (`app/services/repository_fetcher.rb`)
- [x] Multi-query execution with deduplication by `full_name`
- [x] Smart prioritization: Sort by stars, analyze top 5, show others unanalyzed
- [x] Created `analyze:fetch` rake task for testing
- [x] Fixed critical bugs:
  - Fixed `needs_analysis?` method (wrong method name `last_analysis` → `analysis_last`)
  - Removed reference to non-existent `stargazers_at_analysis` column
  - Fixed category lookup (AI returns `slug`, not `category_id`)
  - Categories now auto-created via `find_or_create_by!`
- [x] Performance optimization: Second run 4x faster (no AI calls for analyzed repos)

## Step 3: Comparative Analysis Service (gpt-4o) ✅ COMPLETE

- [x] Create `RepositoryComparer` service (`app/services/repository_comparer.rb`)
- [x] Build comprehensive comparison prompt including:
  - User's original query and constraints
  - All repos with metadata (stars, age, language)
  - Tier 1 summaries and categories for each repo
  - GitHub quality signals (activity, issues, health)
- [x] Request structured JSON response with recommended_repo, reasoning, and ranking
- [x] Parse AI response and create Comparison record
- [x] Link to repositories via `comparison_repositories` with rank, score, pros, cons
- [x] Auto-assign categories based on problem_domain extraction via `comparison_categories`
- [x] Track tokens and cost (~3000 tokens = $0.045)
- [x] Created prompts:
  - `app/prompts/repository_comparer_system.erb`
  - `app/prompts/repository_comparer_build.erb`
- [x] NOTE: Uses synchronous service instead of background job (simpler for MVP, 10-15s response time acceptable)

## Comparison UI ✅ COMPLETE

- [x] Create `ComparisonsController` with index, create, show actions
- [x] Set root route to `comparisons#index`
- [x] Build search input page (`comparisons/index.html.erb`) with:
  - Large centered search box with placeholder
  - 5 example query buttons (Rails jobs, Python ORM, React state, Go framework, Node testing)
  - Beautiful landing page design with Tailwind
- [x] Build comparison results page (`comparisons/show.html.erb`) with:
  - Sticky header with search bar (can search again from results)
  - Query info display (tech stack, problem domain, repo count)
  - Highlighted recommendation card with reasoning at top
  - Ranked repository cards showing:
    - Rank badge and score (/100)
    - GitHub stats (stars, forks, language)
    - Fit reasoning in highlighted box
    - Pros (green checkmarks) and Cons (orange X marks)
    - Links to GitHub repos
  - Footer with view count and cost tracking
- [x] Full end-to-end flow working: search → parse → fetch → analyze → compare → display
- [x] Turbo-enabled forms with flash messages
- [x] Auto-increment view_count on each comparison view

## Browsable Comparisons

- [x] `/comparisons` index page exists (clean search interface by design)
- [x] Increment `view_count` when comparison viewed (implemented in show action)
- [x] Comparison model has scopes for recent, popular, cached, by_problem_domain

**Note**: Additional browse/filter/search features deferred to Phase 4 UI enhancement.

## Category Assignment

- [x] Auto-infer category from `problem_domain` extraction (implemented in `RepositoryComparer#link_comparison_categories`)
  - "background job library" → find/create "Background Job Processing"
- [x] Link via `comparison_categories` join table with `assigned_by: "inferred"`

## Cost Controls

- [x] Max repos per comparison: 15 (hard limit enforced in RepositoryFetcher)
- [x] Cost estimate displayed on homepage: "~$0.05 per search"
- [x] Rate limiting configured via Rack::Attack (25/day per user, 5/day per IP)
- [x] Comparison costs tracked in `ai_costs` table automatically via OpenAi service
- [x] Fuzzy query caching saves ~$0.05 per duplicate (Phase 3.6)

## Testing & Validation ✅ COMPLETE

- [x] Comprehensive testing infrastructure via rake tasks:
  - `analyze:compare` - Full pipeline test (parse → fetch → compare)
  - `analyze:fetch` - Steps 1 & 2 test (parse → fetch)
  - `analyze:test_suite` - 30 diverse queries with statistics
  - `analyze:validate_queries` - Expected repos validation
  - `analyze:repo` - Single repo Tier 1 analysis
- [x] Test with various query types:
  - Well-defined: "Rails background job with retry logic" ✓
  - Vague: "job thing for rails" ✓
  - Too specific: "Sidekiq alternative that uses PostgreSQL" ✓
  - Cross-language: "authentication library" ✓
  - Language-agnostic: "docker monitoring", "charting library" ✓
- [x] Verify GitHub search quality (100% success rate on 30-query test suite)
- [x] Validate AI comparison reasoning (manual testing confirms quality)
- [x] Check cost tracking accuracy (automatic via `OpenAi` service wrapper)

---

# Phase 3.6: Core Infrastructure Hardening 🎯 HIGHEST PRIORITY

**Goal**: Strengthen the core application before adding user management complexity.

**Why This Comes First**:

- Prevents runaway costs from duplicate queries (caching saves 80%+)
- Adds reliability through proper error handling
- Secures inputs before multiple users start using the app
- Establishes transparent cost expectations

**Estimated Time**: 2-3 hours total

## Query Caching & Deduplication 💰 (Biggest Cost Saver) ✅ COMPLETE

- [x] Implement fuzzy query matching with PostgreSQL pg_trgm extension
  - [x] Created migration: `enable_pg_trgm_for_comparisons.rb`
  - [x] Added `normalized_query` column to comparisons table
  - [x] Added GIN trigram index for fast similarity searches
  - [x] Pure SQL backfill (100x faster than Ruby iteration)
  - [x] Implemented `Comparison.find_similar_cached(query)` method
  - [x] Returns tuple: `[comparison, similarity_score]`
- [x] Environment-based configuration (no hardcoded defaults)
  - [x] `COMPARISON_SIMILARITY_THRESHOLD` env var (set to 0.8 for ~99% accuracy)
  - [x] `COMPARISON_CACHE_DAYS` env var (set to 7 days)
  - [x] Created `.env` and `.env.example` files
  - [x] Added `dotenv-rails` gem for development/test
  - [x] Fail-fast pattern: `ENV.fetch` without defaults catches config bugs
- [x] ComparisonCreator service integration
  - [x] `find_cached_comparison` checks similarity threshold
  - [x] Returns `{ record:, cached: true, similarity: }` if found
  - [x] Increments `view_count` on cached hits
  - [x] Controller shows cache notice: "Showing cached results from X ago"
- [x] Enhanced validations
  - [x] `validates :normalized_query, presence: true`
  - [x] `validates :user_query, length: { minimum: 1, maximum: 500 }`
  - [x] Custom validation: `user_query_not_blank` (rejects whitespace-only)
- [x] Testing infrastructure
  - [x] Created `lib/tasks/comparison_cache.rake` with helper class
  - [x] `comparison_cache:test_threshold` - Test accuracy at different thresholds
  - [x] `comparison_cache:analyze_real_queries` - Analyze production queries
  - [x] `comparison_cache:test_query[q1,q2]` - Test specific query pair
  - [x] `comparison_cache:stats` - Cache statistics dashboard
  - [x] Moved ComparisonSimilarityTester into rake task (not production code)
- [x] Cache status indicator on comparison show page (already existed)
  - "Cached results from X ago" with yellow/blue badges
  - "Re-run with Fresh Data" button available
- [x] Tested caching behavior
  - Exact match: 100% similarity, cached ✓
  - Case variations: 100% similarity, cached ✓
  - Threshold tuning: 0.8 provides ~99% accuracy ✓
  - Real production data: all duplicates were exact matches ✓

**Cost Impact**: Saves $0.045-$0.05 per duplicate query (90%+ of comparison cost)

## Input Validation & Sanitization 🔒 ✅ COMPLETE

- [x] Add query validation at controller level (`ComparisonsController#create`)
  - [x] Guard clauses with early returns for blank queries
  - [x] Enforce maximum length: 500 characters
  - [x] Strip whitespace before processing via `query` helper method
  - [x] Helpful error messages: "Please enter a search query", "Query too long"
- [x] Add validation to comparison form view (`comparisons/index.html.erb`)
  - [x] Client-side: HTML5 `maxlength="500"` attribute
  - [x] Client-side: `required` attribute
  - [x] Character counter: DEFERRED (nice-to-have, not MVP-critical)
- [x] Add model-level validations (`Comparison` model)
  - [x] `validates :user_query, presence: true, length: { minimum: 1, maximum: 500 }`
  - [x] `validates :normalized_query, presence: true`
  - [x] Custom validation: `user_query_not_blank` prevents whitespace-only queries
- [x] Strengthen `Prompter.sanitize_user_input` method
  - [x] Reviewed existing filters in `app/services/prompter.rb`
  - [x] Already has: strip, limit length, remove control chars, collapse whitespace
  - [x] DEFERRED: Additional adversarial testing (Phase 3.7 security hardening)
- [x] Test validation edge cases
  - [x] Empty query → error message ✓
  - [x] 500+ character query → error message ✓
  - [x] Query with only spaces → model validation fails ✓
  - [x] Normal query → works ✓

**Security Impact**: Prevents abuse and most common prompt injection attacks

## Error Handling & Graceful Degradation 🛡️ ✅ COMPLETE

- [x] Add error handling to `ComparisonsController#create`
  - [x] Wrapped comparison pipeline with rescue clauses
  - [x] Handle `Octokit::TooManyRequests` → "GitHub rate limit exceeded. Please try again in a few minutes."
  - [x] Handle `OpenAI::Errors` → "AI service temporarily unavailable. Please try again in a few moments."
  - [x] Handle `Faraday::Error, Faraday::TimeoutError` → "Network error occurred. Please check your connection and try again."
  - [x] Handle `ComparisonCreator::InvalidQueryError` → "Invalid query: {message}"
  - [x] Handle `ComparisonCreator::NoRepositoriesFoundError` → "No repositories found for your query. Try different keywords."
  - [x] Handle `StandardError` → "Something went wrong. Please try again or contact support if the issue persists."
  - [x] Error logging: DEFERRED (only log actual errors, not success - Rails already logs requests)
- [x] Add custom error classes to `ComparisonCreator` service
  - [x] `ComparisonCreator::InvalidQueryError` - Raised when query parsing fails
  - [x] `ComparisonCreator::NoRepositoriesFoundError` - Raised when GitHub search returns 0 results
  - [x] Both inherit from StandardError for proper exception hierarchy
- [x] Custom error classes in `Github` service
  - [x] DEFERRED: Using Octokit exceptions directly (simple, no custom wrapper needed for MVP)
- [x] Custom error classes in `OpenAi` service
  - [x] DEFERRED: Using OpenAI gem exceptions directly (simple, no custom wrapper needed for MVP)
- [x] Error handling in `UserQueryParser` service
  - [x] Returns `valid: false` with `validation_message` for unparseable queries
  - [x] ComparisonCreator raises InvalidQueryError when `valid: false`
- [x] Error handling in `RepositoryFetcher` service
  - [x] Logs GitHub search failures with Rails.logger.error
  - [x] Raises NoRepositoriesFoundError when `top_repositories.empty?`
  - [x] Logs Tier 1 analysis failures (continues execution with partial data)
- [x] Error handling in `RepositoryComparer` service
  - [x] DEFERRED: Advanced JSON validation (Phase 3.7 - AI already returns valid JSON 99%+ of time)
- [x] Test error scenarios
  - [x] Invalid query → helpful error message ✓
  - [x] Empty search results → "No repositories found" message ✓
  - [x] Rate limit handling ready (rescue clause in place)
  - [x] Network error handling ready (rescue clause in place)
  - [x] OpenAI error handling ready (rescue clause in place)

**Reliability Impact**: App doesn't crash on API failures, users get helpful feedback

## Cost Transparency & Limits 💵 ✅ COMPLETE

- [x] Display cost estimate on homepage (`comparisons/index.html.erb`)
  - [x] Added text below search box: "Each search analyzes up to 10 repositories using AI (~$0.05 per search)"
  - [x] Styled with Tailwind: `text-xs text-gray-500 text-center mt-2`
- [x] Enforce max repos per comparison in `RepositoryFetcher`
  - [x] Set `DEFAULT_LIMIT = 10`
  - [x] Set `MAX_LIMIT = 15`
  - [x] Clamp user-provided limit: `limit = [[limit, MAX_LIMIT].min, 1].max`
  - [x] Documented in code comments: "Maximum repositories to fetch per comparison (cost control)"
- [x] Add cost breakdown to comparison show page
  - [x] Footer shows: "Analysis powered by AI • {view_count} views • Cost: ${cost_usd.round(6)}"
  - [x] Already exists in comparison show view
  - [x] DEFERRED: "How pricing works" documentation page (Phase 4 polish)

**Cost Impact**: Users understand costs upfront, hard limit prevents runaway expenses (max $0.75 per comparison)

## Code Organization & Refactoring 🏗️ ✅ COMPLETE

- [x] Create ComparisonCreator orchestrator service
  - [x] Follows "Doer" naming pattern (not ComparisonCreatorService)
  - [x] Coordinates UserQueryParser, RepositoryFetcher, RepositoryComparer
  - [x] Pipeline pattern: `find_cached_comparison || create_new_comparison`
  - [x] Returns self with attr_reader: `.record`, `.cached`, `.similarity`
  - [x] Custom exceptions: `InvalidQueryError`, `NoRepositoriesFoundError`
  - [x] Organized code: Public Instance → Class → Private sections
- [x] Refactor ComparisonsController
  - [x] Reduced from 70+ lines to ~45 lines
  - [x] Extracted memoized helper methods: `query`, `force_refresh`, `comparison`, `notice`
  - [x] Guard clauses for validation (early returns)
  - [x] Lazy execution: comparison only created if validation passes
  - [x] Clean rescue clauses for all error types
- [x] DRY up rake tasks
  - [x] Updated `analyze:compare` to use ComparisonCreator.call
  - [x] Removed manual orchestration (parse → fetch → compare)
  - [x] Single source of truth for comparison creation logic
- [x] Move test utilities out of production code
  - [x] Moved ComparisonSimilarityTester from app/services into lib/tasks/comparison_cache.rake
  - [x] Only loaded when rake task runs, not in production
  - [x] Verified: `bin/rails runner "ComparisonSimilarityTester"` raises NameError ✓

## Documentation & Logging Improvements 📝

- [x] Add logging for comparison creations
  - [x] SIMPLIFIED: Only log errors (warn/error levels)
  - [x] Rails already logs all requests/responses (no need for success logging)
  - [x] Services log errors with context (RepositoryFetcher, etc.)
- [x] Document cost optimization strategies in CLAUDE.md
  - [x] Query caching strategy with pg_trgm fuzzy matching
  - [x] Why we limit repos per comparison (cost control)
  - [x] Tier 1 vs Tier 2 vs Tier 3 cost tradeoffs already documented
  - [x] Environment variable configuration documented in .env.example

**Note**: Performance monitoring (comparison timing, slow query logging) deferred to future enhancements.

---

# Phase 3.8: Testing & Code Quality ✅ COMPLETE

**Goal**: Build comprehensive test coverage and refactor production code for maintainability.

**Completed**: All tasks accomplished in 1 focused session (6+ hours)

## Code Refactoring & Cleanup ✅ COMPLETE

- [x] Remove rake-only methods from services and models
  - [x] Removed 6 methods from `Github` service (authenticated?, current_user, issues, rate_limit_status, readme, repository)
  - [x] Removed 7 methods from `AiCost` model (average_cost_per_token, cost_by_model, cost_on, cost_per_token, for_model, rollup_daily, total_input_tokens, total_output_tokens, total_tokens)
  - [x] All rake-only functionality moved to rake tasks (not production code)
- [x] Establish single source of truth for OpenAI pricing
  - [x] Made `OpenAi.calculate_cost` public (class method)
  - [x] Updated `Analysis` and `Comparison` models to delegate to `OpenAi.calculate_cost`
  - [x] Eliminated hardcoded pricing rates from models
- [x] Clean up SQL in models using Rails patterns
  - [x] Simplified `Comparison#recommended_repository` from 5 lines to 1 line
  - [x] Created `HomepageComparisonsQuery` query object for complex homepage SQL
  - [x] Added `Analysis.created_on(date)` scope for date filtering
  - [x] Added `Comparison.with_similarity_to(query, threshold)` scope for fuzzy matching
- [x] Add state transition guards
  - [x] Added guards to `QueuedAnalysis` state transitions (pending → processing → completed/failed)
  - [x] Prevents invalid state changes without state_machines gem dependency
- [x] Organize all code with consistent structure
  - [x] All services follow: Public Instance → Class → Private sections
  - [x] All methods alphabetized within sections (except initialize first)
  - [x] All class methods use `class << self` pattern (not `def self.method_name`)
  - [x] Consistent section headers with `#--------------------------------------`

## Testing Infrastructure ✅ COMPLETE

- [x] **Security Tests** (12 tests, 27 assertions)
  - [x] Created `test/models/user_test.rb`
    - OAuth whitelist enforcement (only GitHub OAuth allowed)
    - GitHub ID presence validation
    - Rate limiting logic (`can_create_comparison?` method)
    - Daily limit tracking (`comparisons_created_today` method)
    - Admin override logic (admins bypass rate limits)
  - [x] Created `test/controllers/mission_control_test.rb`
    - Unauthenticated users redirected to root
    - Non-admin users redirected to root
    - Admin users can access /jobs dashboard
    - Empty admin IDs raises error (fail-closed security)
    - Mission Control authentication integration
- [x] **Cost Control Tests** (7 tests, 15 assertions)
  - [x] Created `test/models/comparison_test.rb`
    - Fuzzy cache matching with pg_trgm extension
    - Similarity threshold enforcement (0.8 minimum)
    - Normalized query generation (lowercase, stripped, squished)
    - Cache hit increments view_count
    - Cache expiration after configured days
    - `with_similarity_to` scope functionality
- [x] **Data Integrity Tests** (7 tests, 15 assertions)
  - [x] Created `test/models/repository_test.rb`
    - Repository deduplication by `full_name`
    - `find_or_create_from_github` creates new repos
    - `find_or_create_from_github` updates existing repos
    - Handles GitHub API response format correctly
    - Quality signals tracked (stars, forks, language, activity)
- [x] **Presenter Tests** (12 tests, 30 assertions)
  - [x] Created `test/presenters/home_page_presenter_test.rb`
    - Stats calculation (repositories_count, comparisons_count, total_views, total_ai_cost)
    - Stats caching (10 minute expiration)
    - Trending comparisons (most_helpful, newest, popular_this_week)
    - Category filtering (top_problem_domains, top_architecture_patterns, top_maturity_levels)
    - Cache invalidation (`invalidate_stats_cache` class method)
- [x] **System Tests - Homepage UI** (9 tests, 30 assertions)
  - [x] Updated `test/system/homepage_test.rb`
    - Unauthenticated user sees auth section and comparisons
    - Authenticated user sees search section and comparisons
    - Stats bar displays correctly (public stats visible, admin stats only for admins)
    - Trending section displays when comparisons exist
    - Browse categories section displays correctly
    - Comparisons list displays comparison cards
    - Empty state when no comparisons exist
    - Different empty state for authenticated users
    - Search form submits query
- [x] **Test Results**: 63 tests, 152 assertions, all passing ✅

## Mission Control Configuration ✅ COMPLETE

- [x] Configure Mission Control Jobs authentication
  - [x] Created `config/initializers/mission_control.rb`
  - [x] Skipped HTTP Basic Auth (uses Devise instead)
  - [x] Added custom authentication check via `check_admin_access!`
  - [x] Only allows users with GitHub ID in `MISSION_CONTROL_ADMIN_IDS` env var
  - [x] Fail-closed security: Raises error if no admin IDs configured
  - [x] Redirects unauthenticated users to sign in
  - [x] Redirects non-admin users to root with alert
- [x] Add helper method for admin checks
  - [x] Created `ApplicationHelper#current_user_admin?`
  - [x] Checks GitHub ID against `MISSION_CONTROL_ADMIN_IDS` env var
  - [x] Returns false if not signed in
  - [x] Used in views to conditionally show admin features
- [x] Security testing
  - [x] Verified unauthenticated users cannot access /jobs
  - [x] Verified non-admin authenticated users cannot access /jobs
  - [x] Verified admin users can access /jobs dashboard
  - [x] Verified empty admin IDs raises error (fail-closed)

## Model Improvements ✅ COMPLETE

- [x] **Category Model** - Fixed uniqueness and fuzzy matching bugs
  - [x] Changed uniqueness validation to scope by `category_type` (was global)
  - [x] Created migration: `change_category_slug_uniqueness_scope.rb`
  - [x] Fixed parameterize bug in `find_similar` method
  - [x] Increased fuzzy match threshold from 50% to 70% (prevents false positives)
  - [x] Both `find_or_create_by_fuzzy_match` and `find_similar` now normalize slugs with `.parameterize`
- [x] **Comparison Model** - Added scopes and simplified methods
  - [x] Created `with_similarity_to(query, threshold)` scope for fuzzy cache matching
  - [x] Simplified `recommended_repository` from complex SQL to single line: `comparison_repositories.order(:rank).first&.repository`
  - [x] Updated `calculate_cost` to delegate to `OpenAi.calculate_cost` (single source of truth)
- [x] **Analysis Model** - Added date filtering scope
  - [x] Created `created_on(date)` scope: `where('DATE(created_at) = ?', date)`
  - [x] Replaces inline SQL strings in AiCost rake tasks
- [x] **QueuedAnalysis Model** - Added state transition guards
  - [x] `start!` method validates state is pending before transitioning
  - [x] `complete!` method validates state is processing before transitioning
  - [x] `fail!` method validates state is processing before transitioning
  - [x] Prevents invalid state changes without state_machines gem

## Homepage UI Improvements ✅ COMPLETE

- [x] **User Experience Fixes**
  - [x] Removed navbar (was only shown when signed in - inconsistent UX)
  - [x] Added user menu to top-right of header (GitHub avatar, username, sign out button)
  - [x] Made admin stats conditional (Total Views, Total AI Spend only shown to admins)
  - [x] Fixed pagination from 20 to 18 items (divisible by 3 for grid layout)
- [x] **HomePagePresenter**
  - [x] Organized methods with inline comments by category
  - [x] Stats (cached for performance - 10 minute expiration)
  - [x] Trending Comparisons (most_helpful, newest, popular_this_week)
  - [x] Top Categories (problem_domains, architecture_patterns, maturity_levels)
  - [x] Cache invalidation class method
- [x] **Stats Bar Component** (`app/views/comparisons/_stats_bar.html.erb`)
  - [x] Uses `current_user_admin?` helper to conditionally show stats
  - [x] Grid layout adjusts: 4 columns for admins, 2 columns for regular users
  - [x] Public stats: Repositories Indexed, Comparisons Created
  - [x] Admin-only stats: Total Views, Total AI Spend
- [x] **System Tests**
  - [x] All 9 homepage system tests passing
  - [x] Verifies admin stats NOT visible to unauthenticated users
  - [x] Verifies search section shown to authenticated users
  - [x] Verifies auth section shown to unauthenticated users

## Query Objects Pattern ✅ COMPLETE

- [x] Created `HomepageComparisonsQuery` query object
  - [x] Extracts complex SQL from `Comparison.for_homepage` scope
  - [x] Uses `DISTINCT ON (normalized_query)` for deduplication
  - [x] Prioritizes recent comparisons (within 7 days) with `UNION ALL`
  - [x] Sorts by view_count DESC, created_at DESC
  - [x] Properly sanitizes SQL with `sanitize_sql_array`
  - [x] Accepts configurable `limit` and `recent_days` parameters
  - [x] Updated `Comparison.for_homepage` scope to delegate to query object
  - [x] Follows Rails convention: Query objects live in `app/queries/`

## Developer Experience Improvements ✅ COMPLETE

- [x] Environment variable documentation
  - [x] Updated `.env.example` with `MISSION_CONTROL_ADMIN_IDS`
  - [x] Documented GitHub OAuth credentials section
  - [x] All existing env vars already documented (COMPARISON_SIMILARITY_THRESHOLD, etc.)
- [x] Code organization standards enforced
  - [x] All services follow consistent structure (Public Instance → Class → Private)
  - [x] All class methods use `class << self` pattern
  - [x] All methods alphabetized within sections
  - [x] Section headers standardized
- [x] Single source of truth established
  - [x] `OpenAi.calculate_cost` for all cost calculations
  - [x] `HomepageComparisonsQuery` for homepage comparison logic
  - [x] `.env` files for all configuration

**Time Invested**: 6+ hours (refactoring, testing, UI fixes, debugging)

**Impact**:

- 47 tests provide confidence in core functionality
- Refactored code is maintainable and follows consistent patterns
- Mission Control dashboard secured for production use
- Homepage UI polished and ready for users
- Admin features properly gated behind authentication

---

# Phase 3.9: Production Stabilization & Bug Fixes ✅ COMPLETE

**Goal**: Fix production bugs discovered during initial testing and improve code quality.

**Date Completed**: November 7, 2025
**Time Invested**: ~3 hours
**Status**: All critical production bugs fixed, test coverage expanded!

## Production Bug Fixes ✅ COMPLETE

- [x] Fixed missing `Repository#analysis_current` method (caused 500 errors)
  - Method was accidentally removed during Phase 3.8 refactoring
  - Returns current Tier 1 analysis: `analyses.tier1.current.first`
  - Added to app/models/repository.rb:27
- [x] Fixed wrong method name in RepositoryFetcher
  - Was calling `analyzer.analyze_repository` (doesn't exist)
  - Fixed to `analyzer.analyze` (correct method name)
  - Updated app/services/repository_fetcher.rb:57
  - Updated lib/tasks/analyze.rake:500
- [x] Fixed CLAUDE.md documentation
  - Updated examples to use correct method name (`analyze` not `analyze_repository`)
  - Updated test counts (63 tests, 152 assertions)
  - Added test philosophy about using realistic fixtures

## Test Coverage Expansion ✅ COMPLETE

- [x] **Repository Model Tests** (7 new tests)
  - `analysis_current` returns current Tier 1 analysis
  - `analysis_current` returns nil when no current analysis exists
  - `analysis_current` ignores Tier 2 analyses
  - `needs_analysis?` returns true when never analyzed
  - `needs_analysis?` returns true when last analyzed over 7 days ago
  - `needs_analysis?` returns false when recently analyzed
  - Created `:no_analyses` fixture for clean testing (no data destruction)
- [x] **RepositoryFetcher Service Tests** (2 new tests)
  - Tests that `analyzer.analyze` is called (not `analyze_repository`)
  - Tests return value structure
  - Catches method name bugs
- [x] **GitHub Test Helpers Extraction**
  - Created `test/support/github_helpers.rb` module
  - Moved `stub_github_search` from test_helper.rb
  - Returns realistic repository data instead of empty arrays
  - Ensures tests exercise real code paths
- [x] **Test Results**: 63 tests, 152 assertions, all passing ✅

## Developer Experience Improvements ✅ COMPLETE

- [x] **CI Rake Tasks** (lib/tasks/ci.rake)
  - `bin/rails ci:all` - Run all CI checks (security, lint, tests)
  - `bin/rails ci:security` - Security scans only
  - `bin/rails ci:lint` - RuboCop only
  - `bin/rails ci:test` - All tests only
  - Mirrors GitHub Actions workflow exactly
  - Allows pre-commit local validation
- [x] **Cache Strategy Simplification**
  - Removed `after_commit :clear_homepage_cache` callback
  - Removed `clear_homepage_cache` private method
  - Changed cache TTL from 10 minutes → 5 minutes
  - Accepts staleness for better performance at scale
  - Added `STATS_CACHE_KEY` constant in HomePagePresenter
  - Kept `invalidate_stats_cache` class method for manual clearing
- [x] **Code Quality**
  - Added `.DS_Store` to .gitignore
  - All code follows RuboCop conventions
  - Array brackets: `[ "item" ]` not `["item"]`

## Why These Bugs Happened (Lessons Learned)

**Root Cause**: Test stubs returned empty data (`items: []`), so code paths calling production methods never executed in tests.

**Prevention**:

- ✅ Use realistic test data instead of empty stubs
- ✅ Create dedicated fixtures (`:no_analyses`) instead of destroying data
- ✅ Test actual behavior, not just "does it not crash"
- ✅ Fixtures reset automatically on teardown (no manual cleanup needed)

**Impact**:

- Production is stable with all critical bugs fixed
- Test coverage gives confidence in core functionality
- CI rake tasks prevent pushing broken code
- Cache strategy scales better (no invalidation on every write)

---

# Phase 3.7: Security & Deployment ✅ COMPLETE

**Goal**: Secure the application and deploy to production with proper hardening.

**Date Completed**: November 6-7, 2025
**Time Invested**: ~7.5 hours total
**Status**: All security measures implemented, tested, and deployed to production!

---

## ✅ COMPLETED: Security Hardening (Tasks 1-3)

**Date Completed**: November 6, 2025
**Time Invested**: ~2.5 hours

### Task 1: Prompt Injection Hardening (OWASP LLM01:2025) - 60 mins

- ✅ Enhanced input filters (15+ context-aware patterns)
  - Model-specific targeting blocked (ChatGPT, GPT, Claude, OpenAI)
  - Credential extraction prevented (api_key, access_token, env variables)
  - System information extraction blocked
  - Data exfiltration attempts filtered (URLs, send to, etc.)
  - Context-aware filters (legitimate security queries allowed)
- ✅ System prompt security constraints (all 3 prompts updated)
- ✅ Output validation (non-blocking monitoring with logging)
- ✅ Integrated into all AI services (UserQueryParser, RepositoryComparer, RepositoryAnalyzer)

### Task 2: Security Headers & CSP - 45 mins

- ✅ Content Security Policy configured (`config/initializers/content_security_policy.rb`)
  - Nonce-based inline protection (Turbo + Tailwind compatible)
  - Strict default-src policy (self + HTTPS only)
  - Microsoft Clarity whitelisted (CSP-friendly analytics)
  - CSP enforcing mode enabled (not report-only)
- ✅ HTTP Security Headers (Rack middleware level - `config/application.rb`)
  - X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
  - Referrer-Policy, Permissions-Policy
- ✅ Production-only HSTS (`config/environments/production.rb`)
- ✅ 7 new integration tests for security headers (52 total tests now)

### Task 3: Security Scans & Fixes - 45 mins

- ✅ Brakeman scan: 1 expected warning (force_ssl - documented as intentional)
- ✅ Fixed: Reverse Tabnabbing (added rel="noopener noreferrer" to external links)
- ✅ Bundler audit: No vulnerable gems found
- ✅ Credentials review: All secrets properly gitignored and encrypted
- ✅ SECURITY_REVIEW.md created (comprehensive audit summary)

### Analytics Configuration

- ✅ Google Analytics removed (CSP incompatible - uses eval())
- ✅ Microsoft Clarity configured (CSP-friendly, free, unlimited)
  - Pageview tracking, session recordings, heatmaps
  - No eval(), no cookies, GDPR-friendly
  - Configured via CLARITY_PROJECT_ID env var

---

## ✅ COMPLETED: Render Deployment (Task 4)

**Date Completed**: November 6-7, 2025
**Time Invested**: ~3 hours (including troubleshooting and documentation)
**Status**: App deployed and live at https://reporeconnoiter.onrender.com

### What Was Completed

- ✅ Created Render account (Starter plan - $14/month for PostgreSQL + Web Service)
- ✅ Provisioned PostgreSQL 17 database
- ✅ Created Web Service with correct build/start commands
- ✅ Set all required environment variables (DATABASE_URL, SECRET_KEY_BASE, RAILS_MASTER_KEY, GitHub OAuth, OpenAI, etc.)
- ✅ Fixed database.yml to use single DATABASE_URL for all connections (primary, cache, queue, cable)
- ✅ Re-enabled ActionMailer (decided to enable now for future use instead of workarounds)
- ✅ Removed app/mailers directory causing eager loading errors
- ✅ One-time database setup via Render Shell:
  - `DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:cache`
  - `DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:queue`
  - `DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:cable`
  - `bin/rails db:seed`
- ✅ Created comprehensive deployment documentation (`docs/RENDER_DEPLOYMENT.md`)
- ✅ App successfully deployed and accessible
- ✅ force_ssl enabled in production (HSTS configured)

### Deployment Lessons Learned

- Rails 8 multi-database setup requires all connections to use same DATABASE_URL on Render
- Solid Cache/Queue/Cable schema files need manual loading on first deploy
- ActionMailer easier to enable now than add workarounds (future-proof)
- Render Starter plan ($7/month) worth it for shell access during initial setup
- `RAILS_MASTER_KEY` required to decrypt credentials.yml.enc in production
- `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` safe for initial schema loading (empty databases)

---

## ✅ COMPLETED: Custom Domain & CI (Tasks 5C & 5D)

**Date Completed**: November 7, 2025
**Time Invested**: ~2 hours
**Status**: Custom domain live with SSL, CI passing, auto-deploy working!

### Task 5C: Custom Domain Setup - COMPLETE

- ✅ Configured DNS in Route53 (A record for root, CNAME for www)
- ✅ Added custom domains in Render (reporeconnoiter.com + www.reporeconnoiter.com)
- ✅ SSL certificate auto-provisioned via Let's Encrypt
- ✅ Created production GitHub OAuth App with custom domain callback
- ✅ Updated Render environment variables with production OAuth credentials
- ✅ Added canonical domain redirect in ApplicationController
  - Redirects www.reporeconnoiter.com → reporeconnoiter.com (301)
  - Redirects reporeconnoiter.onrender.com → reporeconnoiter.com (301)
  - Production-only, preserves full path, SEO-friendly

### Task 5D: CI Fixes - COMPLETE

- ✅ Fixed GitHub Actions by adding stub OAuth env vars to test/system-test jobs
- ✅ Added required env vars for comparison caching (COMPARISON_SIMILARITY_THRESHOLD, COMPARISON_CACHE_DAYS)
- ✅ Fixed system test isolation issue in CI (Capybara sessions persisting between tests)
- ✅ Created `ensure_unauthenticated` helper method in ApplicationSystemTestCase
- ✅ Verified tests pass locally (45 runs, 104 assertions)
- ✅ Enabled Render auto-deploy (waits for green CI checkmark)

### Code Changes

- `app/controllers/application_controller.rb`: Added `redirect_to_canonical_domain` before_action
- `.github/workflows/ci.yml`: Added stub env vars (OAuth + comparison caching)
- `test/test_helper.rb`: Set required env vars for test environment
- `test/application_system_test_case.rb`: Added `ensure_unauthenticated` helper
- `test/system/homepage_test.rb`: Used helper in unauthenticated tests

---

## 📚 Key Learnings from Phase 3.7

### Deployment Insights (Task 4 - Render)
- Rails 8 multi-database setup requires all connections to use same DATABASE_URL on Render
- Solid Cache/Queue/Cable use schema files (db/*_schema.rb) instead of migrations
- Schema files need manual loading on first deploy via `db:schema:load:cache/queue/cable`
- `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` safe for initial schema loading (empty databases)
- ActionMailer easier to enable now than add workarounds (future-proof for emails)
- Render Starter plan ($7/month) worth it for shell access during troubleshooting
- `RAILS_MASTER_KEY` required in production to decrypt credentials.yml.enc
- Free tier limitations: No shell access, no release commands (paid tier needed for ease)
- Database eager loading in production catches issues (ActionMailer, Devise mailers)
- Re-enabling disabled frameworks better than complex workarounds (YAGNI principle)

### Custom Domain & SSL Insights (Task 5C)
- Render auto-provisions SSL via Let's Encrypt (no AWS Certificate Manager needed)
- SSL provisioning takes 5-10 minutes after DNS propagates
- Route53 requires A record for root domain (can't CNAME apex)
- Modern convention: non-www canonical domain (shorter, cleaner)
- Rails-level redirect works fine for managed platforms like Render
- 301 permanent redirect for SEO (tells search engines which is canonical)
- Bot scanners (WordPress, phpMyAdmin) hit all public IPs constantly (normal noise)

### CI/Testing Insights (Task 5D)
- GitHub Actions won't pass without stub OAuth env vars in test environment
- Render waits for green CI before auto-deploying (good safety feature)
- Rails 8 models with `ENV.fetch` need defaults in test_helper.rb (set before require environment)
- CI environments have stricter Capybara session isolation than local
- `Capybara.reset_sessions!` required for CI test isolation (Warden reset not enough)
- Test isolation bugs often work locally but fail in CI (different cleanup behavior)
- Helper methods better than copy-paste for test setup (DRY, self-documenting)
- `ensure_unauthenticated` pattern prevents test pollution in system tests

---

## ✅ Phase 3.7 Status Summary

**All core security and deployment tasks completed!**

App is live at https://reporeconnoiter.com with:
- Full security hardening (CSP, prompt injection defense, security headers)
- Custom domain with SSL
- CI/CD pipeline with GitHub Actions
- Production OAuth flow configured
- Mission Control Jobs dashboard accessible

**Remaining work**: Production verification testing and documentation updates are tracked in the main TODO.md file.

---
