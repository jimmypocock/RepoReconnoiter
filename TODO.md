# RepoReconnoiter - TODO List

Track progress towards MVP release.

## Status Legend

- [ ] Not started
- [x] Complete
- [~] In progress

---

## Phase 0: Initial Setup

- [x] Generate Rails 8 app with Solid Queue
- [x] Configure Tailwind CSS
- [x] Set up Git repository
- [x] Create project documentation (OVERVIEW.md, PLAN.md, CLAUDE.md)

---

## Phase 1: Core Foundation

### GitHub API Integration

- [x] Add Octokit gem to Gemfile
- [x] Store GitHub personal access token in Rails credentials
- [x] Create `Github` API wrapper (`app/services/github.rb`) - follows "Doer" naming pattern
  - [x] Implement search repositories (using Search API)
  - [x] Implement search trending repositories
  - [x] Implement repository details endpoint (README, metadata)
  - [x] Implement issues endpoint (for quality signals)
  - [x] Add rate limit tracking and handling
  - [x] Add authentication with GitHub token
  - [x] Support both instance and class methods via delegation
- [x] Build GitHub API explorer rake task (`lib/tasks/github.rake`)
  - [x] Fetch and display sample trending repos
  - [x] Print available fields and data structure
  - [x] Verify what metadata GitHub actually provides

### Database Schema

- [x] Design migrations based on actual GitHub API data structure (see SCHEMA.md)
- [x] Create `repositories` table with GitHub metadata fields
- [x] Create `analyses` table for AI-generated insights (renamed from `ai_analyses`)
- [x] Create `categories` table for categorization taxonomy
- [x] Create `repository_categories` join table
- [x] Create `queued_analyses` table for batch processing (renamed from `analysis_queue`)
- [x] Create `ai_costs` table for AI spending monitoring (renamed from `cost_tracking`)
- [~] Run migrations and verify schema
- [ ] Deferred: `github_issues` table (will add in Phase 3 for Tier 2 deep dives)

### Models & Validations

- [x] Create `Repository` model with associations and validations
- [x] Create `Analysis` model with cost tracking methods (renamed from `AiAnalysis`)
- [x] Create `Category` model with slug generation
- [x] Create `RepositoryCategory` model
- [x] Create `QueuedAnalysis` model with status enum (renamed from `AnalysisQueue`)
- [x] Create `AiCost` model with aggregation methods (renamed from `CostTracking`)
- [ ] Add model tests for key business logic
- [ ] Deferred: `GithubIssue` model (Phase 3)

### Basic UI & Data Display

- [x] Create repositories controller and index view
- [x] Create basic dashboard showing categorized repo data
- [x] Add Pagy pagination (20 repos per page)
- [x] Style with Tailwind CSS
- [x] Set root route to repositories#index
- [x] Add category filtering by type
- [x] Display AI summaries and confidence scores
- [ ] Create repository show page with full details
- [ ] Add Hotwire Turbo frames for dynamic updates

### Background Jobs - GitHub Sync

- [x] Create `SyncTrendingRepositoriesJob`
- [ ] Configure Solid Queue recurring task in `config/recurring.yml`
- [ ] Add job to fetch trending repos every 20 minutes
- [ ] Implement smart caching (only update if repo changed)
- [ ] Add error handling and retry logic
- [x] Test job execution manually

---

## Phase 2: AI Integration - Tier 1 (Categorization)

### OpenAI API Setup

- [x] Add OpenAI gem to Gemfile
- [x] Create `OpenAi` wrapper (`app/services/open_ai.rb`) - transparent wrapper with automatic cost tracking
- [x] Implement token counting and cost calculation
- [x] Add API key configuration (credentials)
- [x] Create cost tracking helpers
- [x] Test API connection with simple prompt
- [x] Model whitelisting (only gpt-4o-mini and gpt-4o with explicit pricing)
- [x] Automatic daily rollup to `ai_costs` table
- [x] All services use `OpenAi` instead of calling OpenAI directly

### Seed Categories

- [x] Create seeds file with Problem Domain categories
  - Authentication & Identity, Data Sync, Rate Limiting, Background Jobs, etc.
- [x] Create seeds for Maturity Level categories
  - Experimental, Active Development, Production Ready, Enterprise Grade, Abandoned
- [x] Create seeds for Architecture Pattern categories
  - Microservices, Event-driven, Serverless-friendly, Monolith utilities
- [x] Run `bin/rails db:seed` and verify categories

### AI Categorization Job (Tier 1 - Cheap)

- [x] Create `CategorizeRepositoryJob` (uses gpt-4o-mini via `OpenAi` service)
- [x] Create `RepositoryAnalyzer` service (`app/services/repository_analyzer.rb`)
- [x] Create `Prompter` service for AI prompt template rendering (`app/prompts/`)
- [x] Implement prompt for quick categorization
- [x] Parse AI response and assign categories
- [x] Store analysis with token/cost tracking in `analyses`
- [x] Link categories to repository via `repository_categories`
- [x] Add confidence scoring (0.0-1.0)
- [x] Implement smart duplicate detection (auto-create new categories intelligently)
- [x] All models organized with consistent code structure (Public Instance → Class → Private)
- [x] Implement smart caching logic (`Repository#needs_analysis?`)

### Filtering & Display

- [x] Add category filter UI to dashboard
- [x] Display AI-assigned categories on each repo card
- [x] Show category badges with color coding (blue=problem, purple=architecture, green=maturity)
- [x] Display confidence scores as percentages on badges
- [x] Display last analyzed timestamp
- [ ] Add sorting by stars, recent activity, maturity level
- [ ] Add search box for repo name/description

### Cost Monitoring

- [ ] Create admin cost tracking dashboard
- [ ] Show daily/weekly/monthly AI spending
- [ ] Display tokens used per model
- [ ] Add budget warning alerts (approaching $10/month)
- [ ] Create `CostTracking.rollup_daily` method for aggregation

---

## Phase 3: AI Integration - Tier 2 (Deep Analysis)

### Deep Analysis Job (Tier 2 - Expensive)

- [ ] Create `DeepAnalyzeRepositoryJob` (uses gpt-4o)
- [ ] Fetch README content from GitHub
- [ ] Fetch recent issues (last 30 days)
- [ ] Implement comprehensive analysis prompt
  - What problem does it solve?
  - Who is it for?
  - Quality signals from issues
  - Learning opportunities
  - Production readiness assessment
- [ ] Store rich analysis data in `ai_analyses`
- [ ] Add expiration logic (cache for 30 days)

### On-Demand Analysis UI

- [ ] Add "Deep Analyze" button to repository cards
- [ ] Queue analysis job when button clicked
- [ ] Show loading state with Turbo Streams
- [ ] Display deep analysis results in modal or expanded view
- [ ] Rate limit: 3 deep dives per day for free tier
- [ ] Add visual diff between Tier 1 and Tier 2 insights

### Queue Management

- [ ] Create `AnalysisQueueJob` for batch processing
- [ ] Schedule nightly batch processing (max 50 repos/day)
- [ ] Implement priority queue (trending repos first)
- [ ] Add retry logic for failed analyses
- [ ] Create admin UI for queue monitoring

### Budget Controls

- [ ] Implement daily spending cap ($0.50/day max)
- [ ] Pause analysis jobs if budget exceeded
- [ ] Send alerts when approaching limits
- [ ] Create emergency "pause all AI" switch

---

## Phase 3.5: AI Integration - Tier 3 (Comparative Evaluation) 🎯 MVP GOAL

**Use Case**: Junior devs (or anyone) needs to evaluate multiple libraries/tools for a specific need.

**Example Queries:**
- _"I need a Rails background job library with retry logic and monitoring"_
- _"Looking for a Python authentication system that supports OAuth and 2FA"_
- _"Need a React state management library for large applications"_

**Cost per Comparison**: ~$0.045 (220 comparisons per $10 budget)
- Step 1 (Parse): gpt-4o-mini ~$0.0003
- Step 3 (Compare): gpt-4o ~$0.045

### Database Schema

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

### Step 1: Query Parser Service (gpt-4o-mini) ✅ COMPLETE

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

### Step 2: Fetch & Prepare Repos ✅ COMPLETE

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

### Step 3: Comparative Analysis Service (gpt-4o) ✅ COMPLETE

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

### Comparison UI ✅ COMPLETE

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
- [ ] DEFERRED: Extraction verification step with "Edit" button (simplified flow for MVP)
- [ ] DEFERRED: Loading states (synchronous execution is fast enough for MVP)
- [ ] DEFERRED: "View full Tier 1 details" modal

### Browsable Comparisons (/comparisons)

- [x] `/comparisons` index page exists (clean search interface by design)
- [x] Increment `view_count` when comparison viewed (implemented in show action)
- [x] Comparison model has scopes for recent, popular, cached, by_problem_domain
- [ ] Show "Recent Evaluations" list on index page (last 20)
- [ ] Show "Popular Comparisons" list (highest view_count)
- [ ] Filter by category (problem_domain, architecture, maturity)
- [ ] Search existing comparisons before running new one (save $0.045 per duplicate)
- [ ] Show "5 related comparisons in this category" on show page
- [ ] Analytics dashboard: "Top 10 most-compared problem domains"

### Smart Caching & Re-analysis

- [ ] 🎯 **PRE-MVP**: Exact query match returns cached result (within 7 days) - saves $0.05 per repeated query
- [ ] Check if new repos matching criteria appeared on GitHub
- [ ] Prompt user: "Found 2 new repos since last comparison. Re-run?"
- [ ] Background job to refresh popular comparisons monthly
- [ ] Store query variations to match similar requests

### Category Assignment

- [x] Auto-infer category from `problem_domain` extraction (implemented in `RepositoryComparer#link_comparison_categories`)
  - "background job library" → find/create "Background Job Processing"
- [x] Link via `comparison_categories` join table with `assigned_by: "inferred"`
- [ ] AI suggests additional categories during comparison (not implemented - deferred)
- [ ] Display category badges on comparison results page (deferred)

### Cost Controls & Rate Limiting

- [ ] Set max repos per comparison (default 5, max 10)
- [ ] Show cost estimate before running: "This will analyze 5 repos (~$0.05)"
- [ ] Rate limit: 3 comparisons per day for free tier
- [ ] Track comparison costs in `ai_costs` table separately
- [ ] Implement daily spending cap for comparisons
- [ ] Show "X comparisons remaining today" in UI

### Testing & Validation ✅ COMPLETE

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

## Phase 3.6: Core Infrastructure Hardening 🎯 HIGHEST PRIORITY

**Goal**: Strengthen the core application before adding user management complexity.

**Why This Comes First**:
- Prevents runaway costs from duplicate queries (caching saves 80%+)
- Adds reliability through proper error handling
- Secures inputs before multiple users start using the app
- Establishes transparent cost expectations

**Estimated Time**: 2-3 hours total

### Query Caching & Deduplication 💰 (Biggest Cost Saver)

- [ ] Implement exact query match caching in `ComparisonsController#create`
  - Check for existing comparison with same `user_query` in last 7 days
  - Use `Comparison.cached` scope (already exists in model)
  - If found, redirect to cached result instead of creating new comparison
  - Increment `view_count` on cached comparison
  - Show notice: "Showing cached results from X days ago"
- [ ] Add cache status indicator to comparison show page
  - Display "Fresh comparison" vs "Cached from X ago"
  - Option to "Re-run with latest data" button
- [ ] Test caching behavior
  - Search "Rails background jobs" twice → second uses cache ✓
  - Wait 8 days, search again → creates new comparison ✓
  - Search "rails background jobs" (lowercase) → matches cached ✓

**Cost Impact**: With 5 users searching similar queries, saves ~$0.18 per duplicate query (80%+ savings)

### Input Validation & Sanitization 🔒

- [ ] Add query validation at controller level (`ComparisonsController#create`)
  - Reject empty or whitespace-only queries with helpful error
  - Enforce maximum length: 500 characters
  - Strip whitespace before processing
  - Sanitize with `Prompter.sanitize_user_input` before AI calls
- [ ] Add validation to comparison form view
  - Client-side: HTML5 `maxlength="500"` attribute
  - Client-side: `required` attribute
  - Show character counter (optional, nice-to-have)
- [ ] Strengthen `Prompter.sanitize_user_input` method
  - Review existing filters in `app/services/prompter.rb`
  - Add additional malicious pattern filters if needed
  - Test with adversarial inputs (SQL injection attempts, XSS, prompt injection)
- [ ] Test validation edge cases
  - Empty query → error message ✓
  - 600 character query → error message ✓
  - Query with only spaces → error message ✓
  - Normal query → works ✓

**Security Impact**: Prevents abuse and prompt injection attacks

### Error Handling & Graceful Degradation 🛡️

- [ ] Add error handling to `ComparisonsController#create`
  - Wrap comparison pipeline in begin/rescue block
  - Handle `Github::RateLimitError` → show friendly message
  - Handle `OpenAI::Error` → show AI unavailable message
  - Handle invalid queries → show helpful rephrasing suggestion
  - Handle empty results → suggest different keywords
  - Log all errors with full backtrace for debugging
- [ ] Add custom error classes to `Github` service
  - Define `Github::RateLimitError` exception
  - Rescue `Octokit::TooManyRequests` and raise custom error
  - Add rate limit info to error message (resets at X time)
- [ ] Add custom error classes to `OpenAi` service (if needed)
  - Rescue OpenAI gem errors and provide context
- [ ] Add error handling to `UserQueryParser` service
  - Return `valid: false` with `error_message` for unparseable queries
  - Handle API timeouts gracefully
- [ ] Add error handling to `RepositoryFetcher` service
  - Handle GitHub search failures
  - Handle empty result sets
  - Handle Tier 1 analysis failures
- [ ] Add error handling to `RepositoryComparer` service
  - Handle malformed AI responses (invalid JSON)
  - Handle missing required fields in AI response
- [ ] Test error scenarios
  - Invalid query → helpful error message ✓
  - Mock GitHub API failure → graceful error ✓
  - Mock OpenAI API failure → graceful error ✓
  - Empty search results → helpful suggestion ✓

**Reliability Impact**: App doesn't crash, users get helpful feedback

### Cost Transparency & Limits 💵

- [ ] Display cost estimate on homepage (`comparisons/index.html.erb`)
  - Add text: "Each comparison analyzes up to 10 repositories using AI (~$0.05 per search)"
  - Position below search box or in help text
- [ ] Enforce max repos per comparison in `RepositoryFetcher`
  - Set `DEFAULT_LIMIT = 10`
  - Set `MAX_LIMIT = 15`
  - Clamp user-provided limit: `limit = [limit, MAX_LIMIT].min`
  - Document in code comments why limit exists (cost control)
- [ ] Add cost breakdown to comparison show page (optional, nice-to-have)
  - Show tokens used: "Used X input tokens, Y output tokens"
  - Show cost: "This comparison cost $0.045"
  - Link to "How pricing works" documentation

**Cost Impact**: Users understand costs, hard limit prevents runaway expenses

### Documentation & Logging Improvements 📝

- [ ] Add logging for all comparison creations
  - Log: user_query, repos_count, total_cost, processing_time
  - Use Rails.logger.info for successful comparisons
  - Use Rails.logger.error for failures with full context
- [ ] Document cost optimization strategies in CLAUDE.md
  - Explain query caching strategy
  - Explain why we limit repos per comparison
  - Explain Tier 1 vs Tier 2 vs Tier 3 cost tradeoffs
- [ ] Add performance monitoring (optional)
  - Track comparison creation time (parse + fetch + analyze + compare)
  - Log slow comparisons (>30 seconds)
  - Identify bottlenecks for future optimization

---

## Phase 3.7: Security & Access Control 🎯 PRE-LAUNCH PRIORITY

**Goal**: Secure the application for controlled public release with invite-only access.

**Prerequisites**: Phase 3.6 (Core Infrastructure Hardening) must be complete first!

### User Authentication & Authorization

- [ ] Add `users` table migration
  - `github_id` (integer, unique) - GitHub user ID
  - `github_username` (string) - GitHub username
  - `github_name` (string) - Full name from GitHub
  - `github_avatar_url` (string) - Profile picture
  - `email` (string) - Email from GitHub
  - `whitelisted` (boolean, default: false) - Access control flag
  - `whitelisted_at` (datetime) - When access was granted
  - `whitelisted_by_id` (integer) - Admin who granted access
  - `admin` (boolean, default: false) - Admin privileges
  - `last_sign_in_at` (datetime) - Track login activity
  - `comparisons_count` (integer, default: 0) - Cache counter
  - Timestamps
- [ ] Create `User` model with validations
  - Validates uniqueness of github_id and github_username
  - Has many comparisons (for cost tracking)
  - Scopes: whitelisted, admins, recent_sign_ins
- [ ] Add OmniAuth GitHub authentication
  - Add `omniauth-github` gem to Gemfile
  - Configure OmniAuth in `config/initializers/omniauth.rb`
  - Store GitHub OAuth app credentials in Rails credentials
  - Create sessions controller for OAuth callback
- [ ] Add `user_id` to `comparisons` table
  - Migration: `add_reference :comparisons, :user, foreign_key: true`
  - Update Comparison model association: `belongs_to :user, optional: true` (optional for now, required after migration)
- [ ] Update `ai_costs` table to track by user
  - Migration: `add_reference :ai_costs, :user, foreign_key: true`
  - Update AiCost model association: `belongs_to :user, optional: true`
  - Update OpenAi service to accept optional user parameter
- [ ] Implement authentication flow
  - Sign in with GitHub button on homepage (if not authenticated)
  - OAuth callback creates or updates user record
  - Session management (store user_id in session)
  - Current user helper methods in ApplicationController
- [ ] Implement authorization checks
  - Before action filter: `require_whitelisted_user!`
  - Apply to ComparisonsController#create (must be whitelisted to run comparisons)
  - Allow public viewing of comparison results (no auth required)
  - Redirect non-whitelisted users to waitlist page

### Invite/Waitlist System

- [ ] Create waitlist page (`/waitlist`)
  - Shown to non-whitelisted authenticated users
  - Message: "RepoReconnoiter is in private beta. Request access below."
  - Display user's GitHub username and avatar
  - "Request Access" button (records interest)
  - Friendly message: "We'll notify you when your invite is ready!"
- [ ] Create `access_requests` table (optional, for tracking interest)
  - `user_id` (integer, references users)
  - `requested_at` (datetime)
  - `notes` (text) - Optional message from user
  - `status` (enum: pending, approved, denied)
  - Timestamps
- [ ] Admin interface for whitelist management
  - `/admin/users` - List all users with whitelist status
  - Filter: whitelisted, pending, all
  - Bulk actions: "Whitelist selected users"
  - Individual actions: Whitelist, Remove access, Make admin
  - Show user's GitHub profile, comparisons count, cost spent
- [ ] Email notifications (optional for MVP, can add later)
  - Notify user when whitelisted (via Action Mailer)
  - Welcome email with getting started guide

### Rate Limiting & Abuse Prevention

- [ ] Add `rack-attack` gem to Gemfile
- [ ] Configure Rack::Attack in `config/initializers/rack_attack.rb`
  - Throttle comparison creation: 5 requests per 10 minutes per user
  - Throttle comparison creation: 20 requests per 10 minutes per IP (for anonymous viewing)
  - Block suspicious patterns (too many failed OAuth attempts)
  - Whitelist localhost for development
- [ ] Add rate limit tracking to User model
  - `comparisons_today_count` - Cache counter (reset daily via background job)
  - `daily_comparison_limit` (integer, default: 10) - Configurable per user
  - `daily_comparison_limit_override` (integer, nullable) - For special users
- [ ] Implement daily limit checks in controller
  - Before creating comparison, check if user.can_create_comparison?
  - Flash message: "You've reached your daily limit of 10 comparisons. Try again tomorrow!"
  - Admins have unlimited comparisons
- [ ] Add cost tracking per user
  - Track AI costs per user via `ai_costs.user_id`
  - User model methods: `total_ai_cost`, `cost_this_month`, `cost_today`
  - Admin dashboard shows top spenders

### Input Validation & Security

- [ ] Add input length validation at controller level
  - Validate `user_query` parameter in ComparisonsController
  - Maximum length: 500 characters
  - Reject empty or whitespace-only queries
  - Sanitize input before passing to AI services
- [ ] Strengthen prompt injection prevention
  - Review `Prompter.sanitize_user_input` method
  - Add additional filters for malicious patterns
  - Test with adversarial inputs (SQL injection attempts, XSS, prompt injection)
- [ ] Add CSRF protection verification
  - Ensure `protect_from_forgery with: :exception` is enabled (Rails default)
  - Verify all forms include CSRF token
- [ ] Add Content Security Policy (CSP)
  - Configure in `config/initializers/content_security_policy.rb`
  - Restrict external scripts, styles, images to trusted sources
- [ ] Add security headers
  - Configure SecureHeaders gem or set manually in ApplicationController
  - X-Frame-Options: DENY
  - X-Content-Type-Options: nosniff
  - X-XSS-Protection: 1; mode=block
  - Strict-Transport-Security (HSTS) for production

### Logging & Audit Trails

- [ ] Add comprehensive logging for AI requests
  - Log all comparison creations with user_id, query, cost, timestamp
  - Log all AI API calls with model, tokens, cost, user_id
  - Log authentication events (sign in, sign out, failed attempts)
  - Log authorization failures (non-whitelisted user attempts)
- [ ] Create audit_logs table (optional, structured logging)
  - `user_id` (integer, nullable)
  - `action` (string) - e.g., "comparison_created", "user_whitelisted"
  - `resource_type` (string) - e.g., "Comparison", "User"
  - `resource_id` (integer)
  - `metadata` (jsonb) - Additional context
  - `ip_address` (string)
  - `user_agent` (text)
  - Timestamps
- [ ] Admin audit log viewer
  - `/admin/audit_logs` - Searchable, filterable log viewer
  - Filter by user, action, resource, date range
  - Export to CSV for analysis

### Cost Monitoring & Budget Controls

- [ ] Admin cost dashboard (`/admin/costs`)
  - Total spend today, this week, this month
  - Spend by user (top 10 users)
  - Spend by model (gpt-4o vs gpt-4o-mini)
  - Daily spend chart (last 30 days)
  - Budget status: "$X.XX / $10.00 monthly budget"
  - Alert banner if approaching limit (>$8.00/month)
- [ ] Implement spending cap enforcement
  - Check total monthly spend before allowing new comparisons
  - If over budget, show message: "We've reached our AI budget for this month. Please try again next month."
  - Admins can override budget limit
  - Log budget limit hits for monitoring
- [ ] Budget alert notifications (optional)
  - Email admin when spend reaches 50%, 75%, 90% of monthly budget
  - Slack/Discord webhook integration for real-time alerts

---

## Phase 4: Polish & MVP Launch

### User Experience

- [ ] Add search functionality (repo name, description)
- [ ] Implement "bookmark" feature for repos
- [ ] Create weekly digest view (top 5 repos this week)
- [ ] Add keyboard shortcuts for navigation
- [ ] Improve mobile responsive design

### Performance & Caching

- [ ] Add database indexes for common queries
- [ ] Implement Solid Cache for expensive queries
- [ ] Add pagination to repositories list
- [ ] Optimize N+1 queries
- [ ] Add background job monitoring

### Deployment Preparation

- [ ] Configure production environment variables
- [ ] Set up PostgreSQL on hosting provider
- [ ] Configure Kamal deployment (`config/deploy.yml`)
- [ ] Set up SSL/TLS with Let's Encrypt
- [ ] Configure error monitoring (Sentry or similar)

### Testing & Security

- [ ] Write integration tests for critical paths
- [ ] Test GitHub API error handling
- [ ] Test OpenAI API error handling
- [ ] Run Brakeman security scan and fix issues
- [ ] Run bundle-audit and update vulnerable gems

### Documentation

- [ ] Update README with setup instructions
- [ ] Document environment variables needed
- [ ] Create API key setup guide
- [ ] Add troubleshooting section

### Launch

- [ ] Pre-launch security checklist
  - [ ] Verify all authentication flows work correctly
  - [ ] Test whitelist enforcement (non-whitelisted users blocked)
  - [ ] Test rate limiting (Rack::Attack configured correctly)
  - [ ] Verify input validation prevents malicious input
  - [ ] Run Brakeman security scan (no critical issues)
  - [ ] Run bundle-audit (no vulnerable gems)
  - [ ] Review Rails credentials (all secrets properly stored)
- [ ] Initial whitelist setup
  - [ ] Whitelist yourself as admin
  - [ ] Whitelist 3-5 trusted friends for beta testing
  - [ ] Document who has access and why
- [ ] Deploy to production with Kamal
  - [ ] Set up production environment variables
  - [ ] Configure GitHub OAuth app for production domain
  - [ ] Set up database backups
  - [ ] Configure SSL/TLS with Let's Encrypt
- [ ] Verify Solid Queue jobs running
- [ ] Monitor first 24 hours for errors
  - [ ] Check error monitoring (Sentry or logs)
  - [ ] Monitor AI spending (should be minimal with 3-5 users)
  - [ ] Check authentication flow (OAuth working correctly)
  - [ ] Verify rate limiting (no false positives)
- [ ] Share with initial whitelisted users
  - [ ] Send access confirmation email
  - [ ] Share public repo URL (code is open source)
  - [ ] Request feedback on UX and comparison quality
  - [ ] Monitor their usage patterns and costs

---

## Future Enhancements (Post-MVP)

### User Personalization

- [ ] Add Sign In With GitHub authentication
- [ ] Create user preferences (tech stack, interests)
- [ ] Personalized recommendations based on user stack
- [ ] User bookmarks and notes on repositories
- [ ] Weekly email digest of relevant repos

### Trend Analysis

- [ ] Create `Trend` model and aggregation jobs
- [ ] Detect rising technologies (e.g., "Vector databases up 200%")
- [ ] Pattern recognition across repos
- [ ] Weekly trend report generation
- [ ] Visualization of technology adoption over time

### Advanced Features

- [ ] Alternative/cheaper AI providers (Gemini Flash)
- [ ] Pro tier subscription ($5/month)
- [ ] API for external integrations
- [ ] Browser extension for GitHub
- [ ] Slack/Discord integration for team notifications

---

## Notes

**Current Status**: ✅ Phases 1, 2, & 3.5 COMPLETE! 🎯 Ready for Phase 3.6 (Core Infrastructure Hardening)

**What's Working** (Fully Functional MVP):
- ✅ **Tier 3 Comparative Evaluation** - End-to-end working!
  - ✅ UserQueryParser service (Step 1) with 100% test success rate
  - ✅ RepositoryFetcher service (Step 2) with multi-query and smart caching
  - ✅ RepositoryComparer service (Step 3) with gpt-4o comparison
  - ✅ Beautiful comparison UI with rankings, pros/cons, scoring
  - ✅ Full flow: search → parse → fetch → analyze → compare → display
- ✅ GitHub API integration and sync job
- ✅ Database schema with 9 tables (6 original + 3 Tier 3)
- ✅ OpenAI Tier 1 categorization (gpt-4o-mini)
- ✅ Smart category auto-creation with duplicate detection
- ✅ Automatic cost tracking with `OpenAi` service wrapper (6 decimal precision)
- ✅ Multi-query strategy (2-3 GitHub queries for comprehensive results)
- ✅ Language-agnostic query support (infrastructure/DevOps/charting/monitoring)
- ✅ Comprehensive testing infrastructure (4 rake tasks, 30-query test suite)
- ✅ Smart prioritization: Top 5 analyzed (synchronous), bottom 5 shown as "Other Options"
- ✅ Performance optimization: 4x faster on cached repos
- ✅ GitHub quality signals: stars/day, activity, forks, issues, archived status
- ✅ Responsive Tailwind UI with excellent UX

**What We Learned**:
- AI can create its own categories intelligently - no need to pre-define everything
- 50% word overlap prevents duplicates (e.g., "finance" vs "trading-finance")
- Tier 1 categorization is FAST and CHEAP (perfect for batch processing)
- **GitHub Search API quirks** (Phase 1 research):
  - Simpler queries (1-2 keywords) > complex queries
  - Use broad problem terms: "processing" not "background job processing"
  - Different libraries use different terminology in their descriptions
  - Field filters (`in:name,description`) are too restrictive
  - Backend frameworks (Rails, Django) should only use language filters
  - Frontend frameworks use TypeScript for modern libs (React, Vue, Angular)
  - Universal `stars:>100` threshold works across all ecosystems
- **Multi-query strategy** (Step 1 completion):
  - Single query can't find ALL relevant libraries - need 2-3 queries for comprehensive results
  - Python ORMs: Need both "orm" and "sqlalchemy" queries to catch Django ORM + SQLAlchemy
  - Node.js: Need both JavaScript and TypeScript queries (Express vs Fastify)
  - Testing frameworks: Need specific library names (Jest) + generic terms
  - User mentions specific services (Stripe, PayPal) → create targeted queries for those
  - AI intelligently determines when multi-query needed vs single query sufficient
- **Query parser philosophy** (Step 1 refinement):
  - Don't be too opinionated - let GitHub's ranking work
  - Accept language-agnostic queries (docker, monitoring, charting, search engines)
  - Only reject truly meaningless queries ("best library", "good tool")
  - Principle-based rules > infinite examples (avoid prompt bloat)
  - Testing holistically (30 queries) catches regressions better than one-by-one
  - Environment variables (QUERY=) easier than rake arguments (no escaping needed)
- **Repository fetcher insights** (Step 2 completion):
  - Synchronous analysis (blocking) is simpler and safer than async for MVP
  - Smart prioritization: Analyze top 5 (best candidates), defer bottom 5 (show unanalyzed)
  - Category lookup bug: AI returns `slug` but code expected `category_id` - always use `find_or_create_by!`
  - Caching is critical: Second run 4x faster when repos already analyzed
  - Fixed subtle bugs: wrong method names (`last_analysis` vs `analysis_last`), missing columns
  - Quality signals should be calculated, not stored: stars/day changes daily, calculate on-demand

**Next Steps - Immediate Path to Launch**:

---

## 🎯 PHASE 3.6 - CORE INFRASTRUCTURE HARDENING (DO THIS FIRST!)

**Why This Is Priority #1**:
Before adding user management complexity, we need a rock-solid foundation:
1. **Query caching** - Saves 80%+ of AI costs from duplicate queries
2. **Input validation** - Prevents abuse before multiple users arrive
3. **Error handling** - App doesn't crash when APIs fail
4. **Cost transparency** - Users understand what they're using
5. **Hard limits** - Prevents runaway costs

**Estimated Time**: 2-3 hours total (one focused work session)

**Implementation Order**:
1. ✅ **Query Caching** (30 min) - Check for cached comparisons before creating new ones
2. ✅ **Input Validation** (15 min) - Validate query length, sanitize input at controller level
3. ✅ **Error Handling** (1 hour) - Graceful degradation for GitHub/OpenAI API failures
4. ✅ **Cost Display** (10 min) - Show cost estimate on homepage
5. ✅ **Max Repos Limit** (5 min) - Enforce maximum 15 repos per comparison
6. ✅ **Testing** (30 min) - Verify all edge cases and error scenarios

**Why This Can't Wait**:
- Without caching: 10 users searching "Rails jobs" = $0.45 wasted on duplicates
- Without validation: Malicious user pastes 10KB prompt = expensive API call
- Without error handling: GitHub rate limit = app crashes for everyone
- Without limits: Someone tries to compare 100 repos = $5 query

---

## 🎯 PHASE 3.7 - SECURITY & ACCESS CONTROL (DO THIS SECOND!)

**Prerequisites**: ✅ Phase 3.6 must be complete first!

**Why This Matters**:
With a solid infrastructure, we can now safely add users:
1. Control costs (only whitelisted users can run comparisons)
2. Prevent abuse (rate limiting per user)
3. Track usage (per-user analytics and cost tracking)
4. Enable controlled beta (invite-only access)

**Estimated Time**: 6-8 hours total (2-3 focused work sessions)

**Implementation Order**:
1. **User Authentication** (2-3 hours)
   - GitHub OAuth with OmniAuth
   - Users table with whitelist flag
   - Session management and current_user helpers
   - Link comparisons and ai_costs to users

2. **Authorization & Whitelist** (2-3 hours)
   - Only whitelisted users can create comparisons
   - Waitlist page for non-whitelisted users
   - Admin interface for whitelist management
   - Whitelist yourself + 3-5 beta testers

3. **Rate Limiting & Monitoring** (1-2 hours)
   - Rack::Attack configuration
   - Per-user daily limits (10/day)
   - Admin cost dashboard
   - Budget alerts

4. **Security Hardening** (1 hour)
   - Brakeman scan
   - CSP and security headers
   - Final testing and checklist

5. **Deploy & Monitor** (1 hour)
   - Production deployment with Kamal
   - Monitor beta users for 1 week
   - Gather feedback and iterate

**Why Public Repo + Invite-Only Access Works**:
- Code is open source (transparency, community contributions welcome)
- Only whitelisted users can USE the app (cost control)
- Public can view comparison results (anonymous read-only access)
- Easy to expand whitelist as we validate costs and quality

**Post-Security Phase**:
Once Phase 3.7 is complete and we have 1 week of controlled beta data:
- Add comparison caching (exact query match saves $0.045)
- Add browsable comparisons list (Recent, Popular, By Category)
- Improve admin dashboard (analytics, trends, top users)
- Consider Tier 2 Deep Analysis feature (if budget allows)
