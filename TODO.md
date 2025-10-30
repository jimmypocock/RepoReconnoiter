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
_"I need a background job library for Rails that handles retries well and has good monitoring"_

### Natural Language Search

- [ ] Create `EvaluateLibrariesJob` (uses gpt-4o-mini for search translation)
- [ ] Parse user query into GitHub search parameters
  - Extract tech stack context (Rails, Python, etc.)
  - Extract problem domain (background jobs, authentication, etc.)
  - Extract constraints (retries, monitoring, production-ready, etc.)
- [ ] Execute GitHub search with translated parameters
- [ ] Fetch top N repos (default 5, max 10)

### Comparative Analysis

- [ ] Create `CompareRepositoriesJob` (uses gpt-4o for comparison)
- [ ] Build comprehensive comparison prompt
  - Include all repos being compared
  - Include user's specific constraints/requirements
  - Include existing Tier 1 analysis if available
- [ ] Parse AI comparison response
  - Ranking with scores
  - Pros/cons for each option
  - Specific recommendation with reasoning
  - Trade-offs between options
- [ ] Store comparison as special `Analysis` type: `tier3_comparison`
- [ ] Track tokens/costs for comparison (expected ~2-3x Tier 2 cost)

### Comparison UI

- [ ] Create `/evaluate` page with search input
- [ ] Show loading state while analyzing repos
- [ ] Display comparison results in table/card format
- [ ] Highlight recommended option
- [ ] Show detailed pros/cons for each repo
- [ ] Link to individual repo pages for deep dives
- [ ] Add "Save Comparison" feature for future reference

### Smart Features

- [ ] Cache comparisons (same query within 7 days)
- [ ] Show "Similar Comparisons" if available
- [ ] Rate limit: 3 comparisons per day for free tier
- [ ] Auto-trigger Tier 1 analysis on repos that need it
- [ ] Option to trigger Tier 2 deep dive on recommended repo

### Cost Controls

- [ ] Set max repos per comparison (default 5)
- [ ] Warn user of estimated cost before running
- [ ] Implement daily comparison limit
- [ ] Track comparison costs separately in dashboard

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
