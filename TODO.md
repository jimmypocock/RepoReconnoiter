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
- [x] Create GitHub API service wrapper (`app/services/github_api_service.rb`)
  - [x] Implement search trending repositories (using Search API)
  - [x] Implement repository details endpoint (README, metadata)
  - [x] Implement issues endpoint (for quality signals)
  - [x] Add rate limit tracking and handling
  - [x] Add authentication with GitHub token
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
- [x] Create `OpenAiService` wrapper (`app/services/openai_service.rb`)
- [x] Implement token counting and cost calculation
- [x] Add API key configuration (credentials)
- [x] Create cost tracking helpers
- [x] Test API connection with simple prompt

### Seed Categories

- [x] Create seeds file with Problem Domain categories
  - Authentication & Identity, Data Sync, Rate Limiting, Background Jobs, etc.
- [x] Create seeds for Maturity Level categories
  - Experimental, Active Development, Production Ready, Enterprise Grade, Abandoned
- [x] Create seeds for Architecture Pattern categories
  - Microservices, Event-driven, Serverless-friendly, Monolith utilities
- [x] Run `bin/rails db:seed` and verify categories

### AI Categorization Job (Tier 1 - Cheap)

- [x] Create `CategorizeRepositoryJob` (uses gpt-4o-mini)
- [x] Implement prompt for quick categorization
- [x] Parse AI response and assign categories
- [x] Store analysis with token/cost tracking in `analyses`
- [x] Link categories to repository via `repository_categories`
- [x] Add confidence scoring (0.0-1.0)
- [x] Implement smart duplicate detection (auto-create new categories intelligently)
- [ ] Implement smart caching logic (`Repository#needs_analysis?`)

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

- [ ] Create `comparisons` table
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
- [ ] Create `comparison_repositories` join table
  - Links Comparison to Repository (many-to-many)
  - `rank` (integer) - Position in ranking (1-5)
  - `score` (integer) - AI score 0-100
  - `pros` (jsonb) - Array of strengths
  - `cons` (jsonb) - Array of weaknesses
  - `fit_reasoning` (text) - Why this fits user's needs
- [ ] Create `comparison_categories` join table
  - Links Comparison to Category (many-to-many)
  - `assigned_by` (string) - "ai" or "inferred"
  - Enables browsing comparisons by category

### Step 1: Query Parser Service (gpt-4o-mini)

- [ ] Create `QueryParserService` (`app/services/query_parser_service.rb`)
- [ ] Parse natural language into structured data
  - Extract tech stack (Rails, Python, React, etc.)
  - Extract problem domain (background jobs, authentication, etc.)
  - Extract constraints/requirements as array
  - Generate GitHub search query string
- [ ] Return validation status (enough info to proceed?)
- [ ] Extract keywords for user verification
- [ ] Cost: ~500 tokens = $0.0003 per parse

### Step 2: Fetch & Prepare Repos

- [ ] Execute GitHub search with generated query
- [ ] Fetch top N repos (default 5, configurable max 10)
- [ ] Filter out archived/disabled repos
- [ ] Check which repos need Tier 1 analysis
- [ ] Auto-trigger Tier 1 for unanalyzed repos
- [ ] Wait for all analyses to complete before comparison
- [ ] Collect GitHub quality signals for each repo:
  - Last commit date (`github_updated_at`)
  - Open issues count
  - Stars vs age (growth velocity)
  - Fork count (community adoption)
  - Archived/disabled status

### Step 3: Comparative Analysis Job (gpt-4o)

- [ ] Create `CompareRepositoriesJob` (`app/jobs/compare_repositories_job.rb`)
- [ ] Build comprehensive comparison prompt including:
  - User's original query and constraints
  - All repos with metadata (stars, age, language)
  - Tier 1 summaries and categories for each repo
  - GitHub quality signals (activity, issues, health)
- [ ] Request structured JSON response:
  ```json
  {
    "recommended_repo": "sidekiq/sidekiq",
    "recommendation_reasoning": "...",
    "ranking": [
      {
        "repo_full_name": "sidekiq/sidekiq",
        "rank": 1,
        "score": 95,
        "pros": ["Proven at scale", "Excellent retry logic"],
        "cons": ["Requires Redis infrastructure"],
        "fit_reasoning": "Perfect match because..."
      }
    ]
  }
  ```
- [ ] Parse AI response and create Comparison record
- [ ] Link to repositories via `comparison_repositories`
- [ ] Auto-assign categories based on problem_domain extraction
- [ ] Track tokens and cost (~3000 tokens = $0.045)

### Comparison UI - /evaluate Page

- [ ] Create `/evaluate` route and controller
- [ ] Build search input page with:
  - Large search box with placeholder examples
  - "What are you looking for?" prompt
  - 3-4 example queries below input
  - "Search" button
- [ ] After submission, show extraction verification:
  ```
  ✓ Tech Stack: Rails, Ruby
  ✓ Problem: Background job processing
  ✓ Requirements: Retry logic, Monitoring
  ✓ Searching GitHub for top 5 matches...
  [Edit] button to refine
  ```
- [ ] Show loading state while:
  - Searching GitHub
  - Running Tier 1 analyses (if needed)
  - Comparing repositories
- [ ] Display comparison results:
  - Highlighted recommendation at top with reasoning
  - Comparison table/cards for all 5 repos
  - Columns: Repo, Stars, Activity, Pros, Cons, Score, Fit
  - GitHub quality signals (last updated, issues count)
  - Category badges for each repo
  - Links to GitHub repos
- [ ] Add "View Analysis Details" to see full Tier 1 summary

### Browsable Comparisons (/comparisons)

- [ ] Create `/comparisons` index page
- [ ] Show "Recent Evaluations" (last 20)
- [ ] Show "Popular Comparisons" (highest view_count)
- [ ] Filter by category (problem_domain, architecture, maturity)
- [ ] Search existing comparisons before running new one
- [ ] Increment `view_count` when comparison viewed
- [ ] Cache comparisons for 7+ days (configurable)
- [ ] Show "5 related comparisons in this category"
- [ ] Analytics: "Top 10 most-compared problem domains"

### Smart Caching & Re-analysis

- [ ] Exact query match returns cached result (within 7 days)
- [ ] Check if new repos matching criteria appeared on GitHub
- [ ] Prompt user: "Found 2 new repos since last comparison. Re-run?"
- [ ] Background job to refresh popular comparisons monthly
- [ ] Store query variations to match similar requests

### Category Assignment

- [ ] Auto-infer category from `problem_domain` in Step 1
  - "background job library" → find/create "Background Job Processing"
- [ ] AI suggests additional categories during comparison
  - Might add "Real-time Communication" if repos do websockets
- [ ] Link via `comparison_categories` join table
- [ ] Display category badges on comparison results

### Cost Controls & Rate Limiting

- [ ] Set max repos per comparison (default 5, max 10)
- [ ] Show cost estimate before running: "This will analyze 5 repos (~$0.05)"
- [ ] Rate limit: 3 comparisons per day for free tier
- [ ] Track comparison costs in `ai_costs` table separately
- [ ] Implement daily spending cap for comparisons
- [ ] Show "X comparisons remaining today" in UI

### Testing & Validation

- [ ] Test with various query types:
  - Well-defined: "Rails background job with retry logic"
  - Vague: "job thing for rails"
  - Too specific: "Sidekiq alternative that uses PostgreSQL"
  - Cross-language: "authentication library"
- [ ] Verify GitHub search quality
- [ ] Validate AI comparison reasoning makes sense
- [ ] Check cost tracking accuracy

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

- [ ] Deploy to production with Kamal
- [ ] Verify Solid Queue jobs running
- [ ] Monitor first 24 hours for errors
- [ ] Check AI spending tracking
- [ ] Share with initial users for feedback

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

**Current Status**: ✅ Phase 1 & 2 COMPLETE! Basic UI dashboard live with smart AI categorization.

**What's Working**:
- ✅ GitHub API integration and sync job
- ✅ Database schema with all 6 tables
- ✅ OpenAI Tier 1 categorization (gpt-4o-mini)
- ✅ Smart category auto-creation with duplicate detection
- ✅ Beautiful Tailwind UI with pagination and filtering
- ✅ Cost tracking built-in (~$0.0002 per repo analyzed)

**What We Learned**:
- AI can create its own categories intelligently - no need to pre-define everything
- 50% word overlap prevents duplicates (e.g., "finance" vs "trading-finance")
- Tier 1 categorization is FAST and CHEAP (perfect for batch processing)

**Next Steps - Path to MVP**:

**Option A: Quick MVP (Recommended)**
1. Run `ai:categorize_all` on remaining repos to populate dashboard
2. Skip Tier 2 (deep dive on single repo) for now
3. Jump directly to **Tier 3 (Comparative Evaluation)** - the killer feature
4. Deploy MVP with comparative library evaluation

**Option B: Methodical**
1. Implement Tier 2 deep dive analysis (single repo with README/issues)
2. Add repository show pages with full analysis
3. Then build Tier 3 comparative evaluation
4. Deploy MVP

**Recommendation**: Option A - get to the most valuable feature (Tier 3 comparative evaluation) ASAP. Tier 2 can be added later if needed.

**Cost Target**: Keep under $10/month for AI API calls during MVP phase

**MVP Philosophy**: The comparative evaluation feature (Tier 3) is the killer feature that makes this tool genuinely useful - like having an experienced tech lead help you choose the right library. This is what we're building toward.
