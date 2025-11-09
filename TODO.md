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
- ✅ Phase 4.0: Comparison Creation Progress UX (Nov 9, 2025)

---

## 🎯 CURRENT PRIORITY: Phase 4.1 - Category & Search Quality (CRITICAL)

## ✅ COMPLETED: Phase 4.0 - Comparison Creation Progress UX

**Status**: ✅ COMPLETE (Nov 9, 2025) - See `docs/TODO/PHASE_4.md` for details

**What was built:**
- Real-time progress updates via ActionCable + Turbo Streams
- Progress modal with step-by-step feedback during comparison creation
- Solid Cable configuration for cross-process broadcasting (worker → browser)
- Search UX improvements (hero search on homepage, synced inputs, navbar scroll behavior)
- Layout standardization (consistent max-w-6xl container across all pages)

**Results:**
- Users now see each pipeline stage in real-time (parsing → searching → comparing → complete)
- No more "is it hung?" confusion during 10-30 second comparison creation
- Search inputs sync between hero and navbar positions
- Production ActionCable properly configured with wss:// and correct domain

---

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

## 🎯 CURRENT PRIORITY: Phase 4.1 - Category & Search Quality (CRITICAL)

**Status**: 🔴 IN PROGRESS - Fix comparison categorization and search discoverability

**Problem**: Poor category coverage and weak search functionality limiting comparison discoverability:
- **Category Coverage**: Only 28.6% of comparisons have categories (10 of 35)
- **Weak Categorization**: Only uses `problem_domain` → `problem_domain` categories (ignores tech_stack, repositories)
- **Category Explosion**: Auto-creates new problem_domain categories without deduplication
- **Search Fails**: Searching "ruby" doesn't find Rails comparisons because search only looks at `user_query` field
- **Missing Taxonomy**: Comparisons don't inherit technology/maturity categories from their repositories

**Example**: Rails background job comparison should have:
- `technology: Ruby`
- `technology: Rails`
- `technology: Sidekiq` (from repos)
- `problem_domain: Background Job Processing`

But currently only gets problem_domain category (if lucky).

**Goal**: Comprehensive categorization and multi-field search for better discoverability.

**Estimated Time**: 3-4 hours

---

### Phase 1: Improve Categorization Logic (1.5 hours)

**Goal**: Assign multiple category types from multiple sources (not just problem_domain)

#### 1.1 Update RepositoryComparer Service (45 mins)

**Current Issue** (`repository_comparer.rb:116-150`):
- Only calls `link_comparison_categories(comparison, problem_domain)`
- Only looks at `problem_domain` category type
- Simple word matching (weak)
- Auto-creates new categories without deduplication check

**Solution**: Extract categories from multiple sources

- [ ] Refactor `link_comparison_categories` → three separate methods:
  - [ ] `link_problem_domain_categories(comparison, problem_domain)`
    - Fuzzy match against existing `category_type: "problem_domain"` categories
    - Only create new category if no good match found (similarity < 0.7)
    - Use `pg_trgm` SIMILARITY for matching

  - [ ] `link_technology_categories(comparison, tech_stack)`
    - Parse tech_stack string ("Rails, Ruby, Sidekiq")
    - For each technology, find or create matching `category_type: "technology"` category
    - Normalize names (e.g., "Ruby on Rails" → "Rails", "Node.js" → "Node.js")

  - [ ] `link_repository_categories(comparison, repositories)`
    - For each repository in comparison, get its categories
    - Aggregate common categories (if 3+ repos have "Redis" technology, add it)
    - Inherit maturity level if repos share same maturity
    - Mark these as `assigned_by: "inherited"`

- [ ] Update `create_comparison_record` to call all three methods:
  ```ruby
  link_problem_domain_categories(comparison, parsed_query[:problem_domain])
  link_technology_categories(comparison, parsed_query[:tech_stack])
  link_repository_categories(comparison, repositories)
  ```

- [ ] Add tests for category assignment logic

#### 1.2 Category Deduplication Helper (30 mins)

- [ ] Create `app/services/category_matcher.rb` service
  - [ ] `find_or_create_category(name:, category_type:)` method
    - Use `pg_trgm` to find similar categories (SIMILARITY > 0.7)
    - Return existing if found, create new if not
    - Normalize names before comparison

  - [ ] `normalize_category_name(name, category_type)` method
    - Technology: titleize ("ruby" → "Ruby", "react" → "React")
    - Problem Domain: titleize ("background jobs" → "Background Jobs")
    - Architecture Pattern: titleize
    - Maturity: map to standard values ("prod ready" → "Production Ready")

- [ ] Update all category creation to use this service
- [ ] Add tests for fuzzy matching and normalization

#### 1.3 Add Category Assignment Tests (15 mins)

- [ ] Test Rails comparison gets "Ruby", "Rails", "Background Job Processing" categories
- [ ] Test technology parsing handles commas, ampersands ("Ruby, Rails & Sidekiq")
- [ ] Test repository category inheritance (3+ repos with same category → comparison gets it)
- [ ] Test deduplication (don't create "Background Jobs" if "Background Job Processing" exists)

---

### Phase 2: Category Cleanup & Backfill (1 hour)

**Goal**: Clean up existing category mess and backfill comparisons

#### 2.1 Category Cleanup Rake Task (30 mins)

- [ ] Create `lib/tasks/categories.rake`

  - [ ] Task: `categories:find_duplicates`
    - List all categories with similar names (SIMILARITY > 0.7)
    - Show potential merges: "Background Jobs" → "Background Job Processing"
    - Don't auto-merge (just report for manual review)

  - [ ] Task: `categories:merge[from_id,to_id]`
    - Merge category `from_id` into `to_id`
    - Update all `repository_categories` and `comparison_categories`
    - Delete old category
    - Add safety checks (confirm category types match)

  - [ ] Task: `categories:normalize_names`
    - Normalize all category names using CategoryMatcher
    - Update existing categories in place
    - Report changes made

- [ ] Run cleanup tasks manually to clean current database

#### 2.2 Comparison Backfill Rake Task (30 mins)

- [ ] Create task: `categories:backfill_comparisons`
  - Loop through all comparisons
  - For each comparison:
    - Get `tech_stack`, `problem_domain`, and `repositories`
    - Run categorization logic (same as new comparisons)
    - Skip if comparison already has 3+ categories (don't re-categorize)
    - Report progress: "Categorized comparison #123: added 5 categories"

  - Add batch processing (100 at a time with progress bar)
  - Add dry-run mode: `categories:backfill_comparisons[dry_run]`
  - Log changes to file for review

- [ ] Delete `lib/tasks/backfill_technology_categories.rake` (superseded by comprehensive categories.rake)

- [ ] Run backfill task to categorize existing 25 comparisons

---

### Phase 3: Improve Search (45 mins)

**Goal**: Search across all relevant fields, not just `user_query`

#### 3.1 Update BrowseComparisonsPresenter (30 mins)

**Current Issue** (`browse_comparisons_presenter.rb:72-76`):
```ruby
scope.where("user_query ILIKE ?", "%#{params[:search]}%")
```
Only searches `user_query` field!

**Solution**: Multi-field search with category inclusion

- [ ] Replace `filter_by_search` method with comprehensive search:
  ```ruby
  scope.where("
    user_query ILIKE :q OR
    tech_stack ILIKE :q OR
    problem_domain ILIKE :q OR
    github_search_query ILIKE :q OR
    EXISTS (
      SELECT 1 FROM comparison_categories cc
      JOIN categories c ON c.id = cc.category_id
      WHERE cc.comparison_id = comparisons.id
      AND (c.name ILIKE :q OR c.slug ILIKE :q)
    )
  ", q: "%#{sanitized_search}%")
  ```

- [ ] Add SQL injection protection (use Arel or parameterized queries)
- [ ] Add search highlighting (optional enhancement)

#### 3.2 Add Search Tests (15 mins)

- [ ] Test: searching "ruby" finds comparisons with:
  - `user_query` containing "ruby"
  - `tech_stack` containing "Ruby" or "Rails"
  - Categories with "Ruby" in name

- [ ] Test: searching "rails" finds:
  - Rails comparisons
  - Ruby on Rails technology tag
  - Comparisons with Rails repos

- [ ] Test: case-insensitive search works ("RUBY" = "ruby")

---

### Phase 4: Testing & Validation (30 mins)

#### 4.1 Manual Testing (20 mins)

- [ ] Create new comparison → verify gets 4-6 categories (not just 1)
- [ ] Search "ruby" → verify finds Rails comparisons
- [ ] Search "background" → verify finds job processing comparisons
- [ ] Browse by category → verify all comparisons properly categorized
- [ ] Check category count → verify no explosion of duplicates

#### 4.2 Data Validation (10 mins)

- [ ] Run: `bin/rails runner 'puts "Comparisons with categories: #{Comparison.joins(:categories).distinct.count}/#{Comparison.count}"'`
  - Target: 95%+ coverage (33+/35)

- [ ] Run: `bin/rails runner 'Category.group(:category_type).count.each { |type, count| puts "#{type}: #{count}" }'`
  - Check for balanced distribution across types

- [ ] Run duplicate check: `categories:find_duplicates`
  - Should find minimal duplicates after cleanup

---

### Success Criteria

- ✅ Comparison category coverage: 95%+ (was 28.6%)
- ✅ Comparisons get 4-6 categories on average (technology + problem_domain + inherited)
- ✅ Search "ruby" finds Rails comparisons
- ✅ Search "background jobs" finds job processing comparisons
- ✅ No category explosion (duplicates cleaned up and prevented)
- ✅ Category assignment is automatic and comprehensive
- ✅ Browsing by category works well for discovery

---

### Files to Create/Modify

**New Files:**
- `app/services/category_matcher.rb` - Fuzzy matching and normalization
- `lib/tasks/categories.rake` - Cleanup and backfill tasks

**Modified Files:**
- `app/services/repository_comparer.rb` - Enhanced categorization logic
- `app/presenters/browse_comparisons_presenter.rb` - Multi-field search
- `test/services/repository_comparer_test.rb` - Category assignment tests
- `test/presenters/browse_comparisons_presenter_test.rb` - Search tests

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
