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
- [ ] Create GitHub API service wrapper (`app/services/github_api_service.rb`)
  - [ ] Implement trending repositories endpoint
  - [ ] Implement repository details endpoint (README, metadata)
  - [ ] Implement issues endpoint (for quality signals)
  - [ ] Add rate limit tracking and handling
  - [ ] Add authentication with GitHub token
  - [ ] Create test/example script to explore available data structure
- [ ] Build GitHub API explorer rake task (`bin/rails github:explore`)
  - [ ] Fetch and display sample trending repos
  - [ ] Print available fields and data structure
  - [ ] Verify what metadata GitHub actually provides

### Database Schema
- [ ] Design migrations based on actual GitHub API data structure
- [ ] Create `repositories` table with GitHub metadata fields
- [ ] Create `ai_analyses` table for AI-generated insights
- [ ] Create `categories` table for categorization taxonomy
- [ ] Create `repository_categories` join table
- [ ] Create `github_issues` table for cached issues
- [ ] Create `analysis_queue` table for batch processing
- [ ] Create `cost_tracking` table for AI spending monitoring
- [ ] Run migrations and verify schema

### Models & Validations
- [ ] Create `Repository` model with associations and validations
- [ ] Create `AiAnalysis` model with cost tracking methods
- [ ] Create `Category` model with slug generation
- [ ] Create `RepositoryCategory` model
- [ ] Create `GithubIssue` model
- [ ] Create `AnalysisQueue` model with status enum
- [ ] Create `CostTracking` model with aggregation methods
- [ ] Add model tests for key business logic

### Basic UI & Data Display
- [ ] Create repositories controller and index view
- [ ] Create basic dashboard showing raw repo data
- [ ] Add Hotwire Turbo frames for dynamic updates
- [ ] Style with Tailwind CSS
- [ ] Set root route to repositories#index

### Background Jobs - GitHub Sync
- [ ] Create `SyncTrendingRepositoriesJob`
- [ ] Configure Solid Queue recurring task in `config/recurring.yml`
- [ ] Add job to fetch trending repos every 20 minutes
- [ ] Implement smart caching (only update if repo changed)
- [ ] Add error handling and retry logic
- [ ] Test job execution manually

---

## Phase 2: AI Integration - Tier 1 (Categorization)

### OpenAI API Setup
- [ ] Add OpenAI gem to Gemfile
- [ ] Create `OpenAiService` wrapper (`app/services/openai_service.rb`)
- [ ] Implement token counting and cost calculation
- [ ] Add API key configuration (credentials)
- [ ] Create cost tracking helpers
- [ ] Test API connection with simple prompt

### Seed Categories
- [ ] Create seeds file with Problem Domain categories
  - Authentication & Identity, Data Sync, Rate Limiting, Background Jobs, etc.
- [ ] Create seeds for Maturity Level categories
  - Experimental, Active Development, Production Ready, Enterprise Grade, Abandoned
- [ ] Create seeds for Architecture Pattern categories
  - Microservices, Event-driven, Serverless-friendly, Monolith utilities
- [ ] Run `bin/rails db:seed` and verify categories

### AI Categorization Job (Tier 1 - Cheap)
- [ ] Create `CategorizeRepositoryJob` (uses gpt-4o-mini)
- [ ] Implement prompt for quick categorization
- [ ] Parse AI response and assign categories
- [ ] Store analysis with token/cost tracking in `ai_analyses`
- [ ] Link categories to repository via `repository_categories`
- [ ] Add confidence scoring (0.0-1.0)
- [ ] Implement smart caching logic (`Repository#needs_analysis?`)

### Filtering & Display
- [ ] Add category filter UI to dashboard
- [ ] Display AI-assigned categories on each repo card
- [ ] Show maturity level badges (🔬 Experimental, ✅ Production Ready, etc.)
- [ ] Add sorting by stars, recent activity, maturity level
- [ ] Display last analyzed timestamp

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

**Current Status**: Rails app generated, ready to build GitHub API service

**Next Steps**:
1. Build GitHub API service wrapper
2. Create explorer rake task to inspect available data
3. Finalize database schema based on actual GitHub API response structure
4. Begin implementing sync jobs

**Cost Target**: Keep under $10/month for AI API calls during MVP phase
