# RepoReconnoiter - TODO List

Track progress towards MVP release and UX enhancement.

## Status Legend

- [ ] Not started
- [x] Complete
- [~] In progress

---

## 🎯 CURRENT STATUS (Updated: Nov 8, 2025)

### ✅ PRODUCTION READY - Core Infrastructure Complete

**Deployment**: <https://reporeconnoiter.com> (Render Standard Plan - 2GB RAM)

**What's Working**:

- ✅ User authentication (GitHub OAuth with whitelist)
- ✅ AI-powered comparisons (multi-query GitHub search + OpenAI analysis)
- ✅ Background jobs (Solid Queue via Puma plugin)
- ✅ Recurring tasks (daily trending sync at 3am, hourly cleanup)
- ✅ Rate limiting (25/day per user, 5/day per IP)
- ✅ Security hardening (CSP, prompt injection defense, security headers)
- ✅ Cost tracking (automatic AI spend monitoring)
- ✅ CI/CD (GitHub Actions + local ci:all task)
- ✅ Custom domain with SSL
- ✅ Mission Control Jobs dashboard (/jobs)

**GitHub API Compliance**: ✅ VERIFIED

- Using authenticated API (5,000 requests/hour limit, well under usage)
- Public data only (search, metadata, READMEs)
- Adding value via AI analysis (not just mirroring GitHub data)
- No personal data sales or scraping
- Aggressive caching (fuzzy matching prevents duplicate API calls)
- Compliant with GitHub Terms of Service Section H

**Test Coverage**: 49 tests, 110 assertions, 0 failures ✅

**Completed Phases**:

- ✅ Phase 0: Initial Setup
- ✅ Phase 1: Core Foundation (GitHub API, Database, Models, Basic UI)
- ✅ Phase 2: AI Integration - Tier 1 Categorization
- ✅ Phase 3.5: AI Integration - Tier 3 Comparative Evaluation (MVP Core)
- ✅ Phase 3.6: Core Infrastructure Hardening
- ✅ Phase 3.7: Security & Deployment
- ✅ Phase 3.8: Testing & Code Quality
- ✅ Phase 3.9: Production Stabilization & Bug Fixes
- ✅ Phase 3.10: Search Quality & Relevance (CRITICAL - Nov 9, 2025)

---

## 🎯 CURRENT PRIORITY: Phase 4 - UI & Navigation Polish (MVP Completion)

## ✅ COMPLETED: Phase 3.10 - Search Quality & Relevance (CRITICAL MVP CORE)

**Status**: ✅ COMPLETE - Core comparison engine significantly improved

**Completed**: All tasks finished, comprehensive testing validated improvements

**What was fixed:**
- 2-query limitation → Now defaults to 3 queries (broad + medium + specific variants)
- Stars threshold too high → Lowered from >100 to >50 (configurable via `config/initializers/github_search.rb`)
- No recency penalties → Added automatic score caps (2+ years = max 40, 1-2 years = max 60)
- Missing terminology → Added ecosystem awareness (Go "state" ≠ React "state")
- Hardcoded 5-repo limit → Now respects `limit: 15` parameter

**Results:**
- "Elixir background jobs": 2 repos → Now finds 10+ including Oban (3,687 stars)
- "Zig memory allocator": 6 repos found with proper 3-query strategy
- Multi-query adoption: 100% (was inconsistent)
- Test coverage: +7 tests (49 total, 110 assertions)

**Files changed:**
- ✅ Created `config/initializers/github_search.rb` for centralized config
- ✅ Updated `user_query_parser_system.erb` - 3-query default, ecosystem awareness
- ✅ Updated `repository_comparer_system.erb` - Recency scoring with automatic penalties
- ✅ Fixed `repository_fetcher.rb` - Removed hardcoded 5-repo limit
- ✅ Added test coverage - Config tests, prompter tests, programmatic query testing
- ✅ Created `lib/tasks/test_queries.rake` - Programmatic testing suite
- ✅ UI improvements - Condensed navbar by default (except homepage)

**Success Criteria Met:**
- ✅ Multi-query strategy used for 100% of searches (3 queries per search)
- ✅ Stale repos get automatic score penalties
- ✅ Comparisons now include 10-15 repositories (not 2-5)
- ✅ Config-based thresholds (easy to adjust without touching prompts)

---

## 🎯 CURRENT PRIORITY: Phase 4.0 - Comparison Creation Progress UX (CRITICAL)

**Status**: 🔴 NEXT - Better user feedback during comparison creation

**Problem**: With 15 repos and 3-query strategy, comparison creation takes 10-30 seconds with minimal feedback. Users only see:
- Top progress bar (not descriptive)
- No indication of what's happening
- No sense of progress through the pipeline
- Can feel "hung" or broken

**Goal**: Provide real-time progress updates at each step of the comparison pipeline.

**Estimated Time**: 2-3 hours

### Architecture Overview

**Technology Stack:**
- **WebSocket Layer**: Turbo Streams over ActionCable (Solid Cable - already configured in Rails 8)
- **Broadcasting**: ActionCable channels for real-time updates
- **Frontend**: Stimulus controller + Tailwind CSS modal
- **Job Processing**: Background job broadcasts progress via channel

**Pipeline Stages** (6 total):
1. **Parse query** (~1 sec) - UserQueryParser extracts search parameters
2. **Execute GitHub searches** (~2-3 sec) - RepositoryFetcher runs 3 queries
3. **Merge and deduplicate** (~1 sec) - Combine results, remove duplicates
4. **Analyze repositories** (~5-10 sec) - RepositoryAnalyzer categorizes 15 repos
5. **Compare repositories** (~5-15 sec) - RepositoryComparer generates AI analysis
6. **Save comparison** (~1 sec) - Persist to database

---

### Phase 1: Backend Infrastructure (1.5 hours)

#### 1.1 ActionCable Channel Setup (20 mins)

- [ ] Create `app/channels/comparison_progress_channel.rb`
  - [ ] Subscribe method with session_id parameter
  - [ ] Unsubscribe cleanup
  - [ ] Stream from `comparison_progress_#{session_id}`

- [ ] Update `app/javascript/controllers/index.js` to register Stimulus controllers

- [ ] Test channel connection in browser console

#### 1.2 Progress Broadcaster Service (30 mins)

- [ ] Create `app/services/comparison_progress_broadcaster.rb`
  - [ ] `initialize(session_id)` - Store session identifier
  - [ ] `broadcast_step(step_name, data = {})` - Send Turbo Stream update
  - [ ] `broadcast_error(message, retry_data = {})` - Send error state
  - [ ] `broadcast_complete(comparison_id)` - Send success + redirect
  - [ ] Private method `stream_name` - Returns channel identifier

- [ ] Define step data structure:
  ```ruby
  {
    step: "analyzing_repositories",
    current: 3,
    total: 15,
    message: "Analyzing sidekiq/sidekiq...",
    percentage: 20
  }
  ```

#### 1.3 Update ComparisonCreator Service (40 mins)

- [ ] Add `session_id` parameter to `initialize` method
- [ ] Initialize `@broadcaster = ComparisonProgressBroadcaster.new(session_id)`
- [ ] Broadcast at each pipeline stage:
  - [ ] **Step 1**: After `UserQueryParser.new.parse(query)` completes
    - Broadcast: "Parsing your query..." (step: parsing_query)
  - [ ] **Step 2**: Before `RepositoryFetcher.new.fetch` starts
    - Broadcast: "Searching GitHub with 3 queries..." (step: searching_github)
  - [ ] **Step 3**: After fetch completes with repo count
    - Broadcast: "Found X repositories, merging results..." (step: merging_results)
  - [ ] **Step 4**: Inside repository analysis loop
    - Broadcast: "Analyzing repository X of Y: owner/name..." (step: analyzing_repositories, current: X, total: Y)
  - [ ] **Step 5**: Before comparison AI call
    - Broadcast: "Comparing all repositories with AI..." (step: comparing_repositories)
  - [ ] **Step 6**: After successful save
    - Broadcast: "Comparison complete!" (step: complete, comparison_id: X)

- [ ] Wrap broadcasts in rescue blocks (don't fail job if broadcast fails)
- [ ] Add error broadcasting in existing rescue blocks

---

### Phase 2: Controller & Job Integration (30 mins)

#### 2.1 Update ComparisonsController (15 mins)

- [ ] Update `create` action to generate `session_id`
  - Use `SecureRandom.uuid` or `session.id.to_s`
- [ ] Pass `session_id` to background job
- [ ] Store `session_id` in session for client-side access
- [ ] Render turbo_stream response that shows progress modal

#### 2.2 Update CreateComparisonJob (15 mins)

- [ ] Add `session_id` parameter to `perform` method
- [ ] Pass `session_id` to `ComparisonCreator.new(user, query, session_id)`
- [ ] Ensure error handling broadcasts failure states

---

### Phase 3: Frontend Progress Modal (1 hour)

#### 3.1 Stimulus Progress Controller (30 mins)

- [ ] Create `app/javascript/controllers/comparison_progress_controller.js`
  - [ ] `connect()` - Subscribe to ActionCable channel
  - [ ] `disconnect()` - Unsubscribe from channel
  - [ ] `updateProgress(data)` - Update UI with step data
  - [ ] `showError(data)` - Display error state
  - [ ] `complete(data)` - Redirect to comparison show page
  - [ ] Private helper methods for updating progress bar, step list

- [ ] Add data attributes for targets:
  - `data-comparison-progress-target="modal"` - Modal container
  - `data-comparison-progress-target="stepList"` - Step checklist
  - `data-comparison-progress-target="currentMessage"` - Current step text
  - `data-comparison-progress-target="progressBar"` - Progress bar fill
  - `data-comparison-progress-target="errorContainer"` - Error message area

#### 3.2 Progress Modal View Component (30 mins)

- [ ] Create `app/views/comparisons/_progress_modal.html.erb`
  - [ ] Modal backdrop (fixed, centered, semi-transparent black overlay)
  - [ ] Modal card (white, rounded, shadow, max-width 600px)
  - [ ] Header: "Creating Your Comparison"
  - [ ] Step list container (6 steps with icons):
    - ✓ Completed steps (green checkmark)
    - ⏳ Current step (spinner animation)
    - ○ Upcoming steps (gray circle)
  - [ ] Current message text (large, bold)
  - [ ] Progress bar (blue fill, animated transition)
  - [ ] Percentage text (e.g., "60% complete")
  - [ ] Error state container (hidden by default, red border/background)
  - [ ] Retry button (hidden by default, shown on error)

- [ ] Add Tailwind CSS classes for animations:
  - Progress bar width transition
  - Spinner rotation
  - Step icon fade-in
  - Modal slide-in animation

- [ ] Add to `app/views/comparisons/create.turbo_stream.erb`:
  - Render progress modal
  - Include session_id in data attribute for Stimulus controller

---

### Phase 4: Error Handling & Recovery (30 mins)

#### 4.1 Error State Broadcasting (15 mins)

- [ ] Update `ComparisonProgressBroadcaster#broadcast_error` to include:
  - Error message (user-friendly)
  - Failed step name
  - Retry payload (session_id, query, user_id)
  - Timestamp

- [ ] Update `CreateComparisonJob` error handling:
  - Catch specific exceptions (RateLimitError, OpenAI::Error, GitHub::Error)
  - Broadcast user-friendly error messages
  - Preserve original error for logging

#### 4.2 Retry Mechanism (15 mins)

- [ ] Add retry button to progress modal
  - [ ] Shows only on error state
  - [ ] Triggers new job with same parameters
  - [ ] Generates new session_id
  - [ ] Resets modal to initial state

- [ ] Add `retry` action to Stimulus controller
  - [ ] Extract retry data from error broadcast
  - [ ] Submit new form request
  - [ ] Reset progress UI

---

### Phase 5: Testing & Polish (30 mins)

#### 5.1 Manual Testing (20 mins)

- [ ] Test full flow: submit query → see all 6 progress steps → redirect to result
- [ ] Test error handling: force API error → see error message → retry successfully
- [ ] Test concurrent comparisons: open two tabs, ensure isolated progress
- [ ] Test network interruption: disconnect/reconnect during progress
- [ ] Test on mobile: modal responsive, touch-friendly retry button
- [ ] Verify no memory leaks: unsubscribe cleans up connections

#### 5.2 Polish & Edge Cases (10 mins)

- [ ] Add subtle fade-in animation for modal appearance
- [ ] Add subtle pulse animation for current step
- [ ] Ensure modal is keyboard-accessible (ESC to cancel - if appropriate)
- [ ] Add loading spinner on retry button click
- [ ] Verify progress percentages are accurate (based on step weights)
- [ ] Add timeout handling (if job takes > 60 seconds, show warning)

### Success Criteria:
- ✅ User sees each step of the process in real-time
- ✅ User knows which repo is being analyzed (1 of 15, 2 of 15, etc.)
- ✅ User can see progress bar advancing
- ✅ No "is it hung?" confusion
- ✅ If error occurs, user sees clear error message with retry option

---

## 🚀 Phase 4 - UI & Navigation Polish (MVP Completion)

**Goal**: Create a modern, browsable interface that showcases comparisons, categories, and trending repos.

**Priority**: Polish the browsing experience after comparison creation UX is solid! 🎨

**Vision**: "Airbnb for open source technology" - A visual, discovery-focused interface where users can:

- Browse comparisons by category/problem domain
- Explore categorized repositories with beautiful, expandable cards
- See trending repos from daily sync
- Find relevant tools without requiring AI search (read-only for non-whitelisted users)

**Estimated Time**: 6-8 hours (can be completed over multiple sessions)

**Current UI State**:

- Homepage: Search box + recent comparisons list
- Comparison show page: AI analysis results
- Mission Control: Admin job dashboard

### 4.1 Information Architecture (Planning - 30 mins)

- [ ] Design primary navigation structure
  - Top nav: Logo, Search, Browse, Sign In/Profile
  - Browse dropdown: Comparisons, Categories, Trending
- [ ] Define page hierarchy
  - Homepage (landing/search)
  - Browse Comparisons (filterable list)
  - Browse Categories (problem domains, architecture patterns, maturity)
  - Browse Trending (daily synced repos)
  - Comparison Show (existing - may need polish)
  - User Profile/Dashboard (my comparisons, usage stats)
- [ ] Sketch responsive layout (desktop, tablet, mobile)
- [ ] Decide on UI patterns (cards, lists, filters, tabs)

### 4.2 Navigation Component (1 hour)

- [ ] Create `app/components/navigation_component.rb` (ViewComponent)
- [ ] Build responsive top navigation
  - Logo/brand (links to home)
  - Search box (global, always visible)
  - Browse menu (dropdown: Comparisons, Categories, Trending)
  - Sign In button (unauthenticated)
  - User avatar + dropdown (authenticated: Profile, Sign Out)
  - Admin link to /jobs (admin users only)
- [ ] Add active state styling (current page highlighted)
- [ ] Mobile hamburger menu (Tailwind + Stimulus)
- [ ] Add to `application.html.erb` layout

### 4.3 Homepage Redesign (1-1.5 hours)

- [ ] Hero section
  - Value proposition ("AI-Powered GitHub Tool Comparisons")
  - Search box (CTA for whitelisted users)
  - Sign in prompt (non-whitelisted users)
- [ ] Recent Comparisons section
  - Card layout (not table)
  - Show query, categories, timestamp, user
  - Link to comparison show page
  - Filter by category (problem domain, architecture, maturity)
- [ ] Trending Repos section (3-column cards)
  - Pull from daily sync job
  - Show: name, stars, description, language
  - Link to GitHub repo
- [ ] Popular Categories section
  - Show top 6 categories by comparison count
  - Card grid with category icon, name, count
  - Link to category browse page

### 4.4 Browse Comparisons Page (1 hour)

- [ ] Create `comparisons#browse` route and action
- [ ] Build filterable comparisons list
  - Filter by category (sidebar or top tabs)
  - Filter by date (last week, month, all time)
  - Search by query text (full-text search)
- [ ] Pagination (Pagy, 20 per page)
- [ ] Card layout with metadata
  - Query text
  - Categories (badges)
  - Repositories included (count + logos)
  - Created date
  - User who created it
- [ ] Empty state for no results
- [ ] Sorting options (newest, most repos, most helpful, most viewed)

### 4.5 Browse Categories Page (45 mins)

- [ ] Create `categories#index` route and action
- [ ] Three-column layout by category type
  - Problem Domain (Rails Jobs, Authentication, etc.)
  - Architecture Pattern (Background Jobs, API Clients, etc.)
  - Maturity Level (Production Ready, Experimental, etc.)
- [ ] Each category shows:
  - Name + description
  - Repository count
  - Comparison count
  - Link to category detail page
- [ ] Responsive grid (1 col mobile, 2 col tablet, 3 col desktop)

### 4.6 Browse Trending Page (45 mins)

- [ ] Create `repositories#trending` route and action
- [ ] Pull repos from `SyncTrendingRepositoriesJob` results
- [ ] Card grid layout
  - Repository name + owner
  - Stars, forks, language
  - Description (truncated)
  - Topics/tags
  - Link to GitHub
  - "Compare Similar Tools" button (if whitelisted)
  - Click card to expand/view details (see 4.6a)
- [ ] Filter by language (dropdown)
- [ ] Sort by stars, recent activity, created date
- [ ] Search by repo name or description
- [ ] Pagination (20 per page)

### 4.7 Repository Detail Views (30-45 mins) - AIRBNB-STYLE EXPANSION

**Vision**: Expandable cards with smooth animations - think Airbnb listing details, not modals.

**Implementation:**

- [ ] Create Stimulus controller (`repo_card_controller.js`) for expand/collapse behavior
- [ ] Add Turbo Frame for lazy-loading full details on first expansion
- [ ] Design expanded card layout (Tailwind)
  - Full description (not truncated)
  - AI-generated summary (if analyzed) with highlighted box
  - Categories with confidence scores as badges
  - GitHub stats (stars, forks, issues, last updated) in visual grid
  - Topics/tags as clickable badges
  - README preview (first 200 words, optional)
- [ ] Actions in expanded state
  - "Compare Similar Tools" button (triggers new comparison)
  - "View on GitHub" link (opens in new tab)
  - "Collapse" button or click card again to minimize
- [ ] Smooth CSS transitions
  - Height animation (max-height + transition)
  - Fade-in effect for expanded content
  - Other cards smoothly shift down to make room
- [ ] Mobile optimization
  - Expanded card takes full width
  - Touch-friendly close buttons
  - Swipe-to-collapse gesture (optional enhancement)

**Design Inspiration**: Airbnb listing cards - clean, spacious, visual hierarchy, buttery animations

### 4.8 Polish & Refinements (1-1.5 hours)

- [ ] Implement Hotwire Turbo Frames for dynamic updates
  - Filter/sort updates without full page reload
  - Search result updates
  - Repository detail modals/expansions
  - Pagination navigation
- [ ] Add loading states (Turbo frame loading indicators)
- [ ] Add empty states (no comparisons, no trending, etc.)
- [ ] Improve error messages (rate limit, API errors, etc.)
- [ ] Add breadcrumbs (Browse > Comparisons > Rails Jobs)
- [ ] Improve mobile responsiveness
- [ ] Add micro-interactions (hover states, transitions, card animations)
- [ ] Accessibility audit (keyboard nav, ARIA labels, contrast, focus states)
- [ ] Performance optimization (lazy load images, minimize N+1 queries, use fragment caching)

---

## 📝 Notes

**Phase History**: See `docs/TODO/PHASE_*.md` for detailed history and learnings from completed phases.

**Future Enhancements**: See `docs/TODO/FUTURE.md` for post-MVP features (user personalization, trend analysis, advanced features).

**Security Documentation**: See `docs/SECURITY_REVIEW.md` for comprehensive security audit summary.

**Deployment Guide**: See `docs/RENDER_DEPLOYMENT.md` for complete deployment instructions.
