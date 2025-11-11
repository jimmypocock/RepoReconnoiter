# RepoReconnoiter - TODO List

Track progress towards MVP release and UX enhancement.

## Status Legend

- [ ] Not started
- [x] Complete
- [~] In progress

---

## 🎯 CURRENT STATUS (Updated: Nov 10, 2025)

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
- ✅ Mission Control Jobs dashboard (/admin/jobs)
- ✅ Category system with 129 canonical categories (tech, problem domains, architecture patterns)
- ✅ Three-layer category matching (aliases, fuzzy matching, semantic embeddings)

**GitHub API Compliance**: ✅ VERIFIED

- Using authenticated API (5,000 requests/hour limit, well under usage)
- Public data only (search, metadata, READMEs)
- Adding value via AI analysis (not just mirroring GitHub data)
- No personal data sales or scraping
- Aggressive caching (fuzzy matching prevents duplicate API calls)
- Compliant with GitHub Terms of Service Section H

**Test Coverage**: 95 tests, 261 assertions, 0 failures ✅ (See `TODO_TEST.md` for coverage gaps)

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
- ✅ Phase 4.1a: Category Infrastructure & Cleanup (Nov 10, 2025)
- ✅ Phase 4.1b: Comprehensive Search & Admin Features (Nov 10, 2025)

---

## 🎯 CURRENT PRIORITY: Phase 4.2 - Test Coverage & Quality (IN PROGRESS)

**Status**: 🔴 CRITICAL - Significant test coverage gaps identified, implementing comprehensive test suite

**See:** `TODO_TEST.md` for detailed test implementation plan

**What's Ready:**
- Comprehensive multi-field search with relevance scoring
- GIN trigram indexes for performance
- Admin refresh capability
- 129 canonical categories with embeddings
- All CI checks passing (95 tests, 261 assertions)

**Next Steps:**
1. **Immediate:** Implement critical test coverage (Phase 1: 43 tests, ~5-6 hours)
   - User.admin? tests (5 tests)
   - ComparisonPresenter tests (5 tests)
   - Search enhancement tests (8 tests)
   - BrowseComparisonsPresenter tests (10 tests)
   - ComparisonsController tests (15 tests)
2. **Then:** Deploy search improvements to production
3. **Then:** Run migration for renamed fields (technologies, problem_domains, architecture_patterns)

---

## ✅ COMPLETED: Phase 4.1a - Category Infrastructure & Cleanup (Nov 10, 2025)

**Status**: ✅ COMPLETE - Comprehensive category system built and tested locally

**What Was Built:**

### 1. Category System (129 Canonical Categories)
- **Technology** (61): AI Assistants, Chatbot Framework, htmx, OpenShift, Redux, SVG, etc.
- **Problem Domain** (49): Data Access, State Management, Web Framework, Icons, Session Management, etc.
- **Architecture Pattern** (19): ORM Framework, Layered Architecture, Data Processing Framework, etc.

### 2. CategoryMatcher Service (`app/services/category_matcher.rb`)
- Three-layer matching system:
  1. **Alias mapping**: "Ruby on Rails" → "Rails", "Node.js" variants, "k8s" → "Kubernetes"
  2. **Fuzzy matching**: PostgreSQL trigram similarity (0.8 threshold)
  3. **Semantic embeddings**: OpenAI embeddings for intelligent matching
- Normalization for technology names (titlecase, common patterns)
- Automatic deduplication prevents category explosion

### 3. Production Migration Tasks
- `categories:map_specific` - Maps 18 overly-specific categories to canonical (e.g., "Rails Wrapper" → "Rails")
- `comparisons:backfill_categories` - Re-parses all comparison queries with clean categories
- `categories:generate_embeddings` - Generates semantic embeddings for new categories
- `categories:test_matrix` - 44-scenario test suite for matching validation

### 4. Database Improvements
- **Seeds file** (`db/seeds/categories.rb`): 129 canonical categories with proper deduplication
- **Seeds runner** (`db/seeds.rb`): Fixed to preserve associations (no longer destroys all categories)
- **Sync task** (`lib/tasks/db_sync.rake`): Auto-fixes environment metadata after production sync
- **Test fixes** (`config/database.yml`): Test suite works with production data sync

### 5. Testing & Quality
- **Test Coverage**: 73 tests (was 49), 184 assertions (was 110), 0 failures
- **CI Checks**: All passing (security, linter, tests)
- **Category Matching**: 44/44 scenarios pass (100%)
- **Comprehensive verification**: Category counts, associations, embeddings, duplicates all validated

**Files Created:**
- `app/services/category_matcher.rb` - Three-layer matching with normalization
- `lib/tasks/map_specific_categories.rake` - Production migration for specific → canonical
- `lib/tasks/backfill_comparison_categories.rake` - Comparison category backfill
- `lib/tasks/generate_embeddings.rake` - OpenAI embedding generation
- `lib/tasks/test_category_matrix.rake` - 44-scenario comprehensive test suite
- `lib/tasks/category_seeds.rake` - Dump canonical categories from database
- `lib/tasks/categories_sync.rake` - Lightweight category-only sync from production

**Files Modified:**
- `db/seeds/categories.rb` - 129 canonical categories (was messy duplicates)
- `db/seeds.rb` - Removed `Category.destroy_all` (now preserves associations)
- `lib/tasks/db_sync.rake` - Auto-fixes environment metadata for test suite
- `test/services/category_matcher_test.rb` - Comprehensive matching tests

**Results:**
- Category count: 142 (production) → 129 (canonical)
- Category quality: Eliminated duplicates, normalized names, proper types
- Repository associations: 264 preserved through migration
- Comparison associations: 13 → 17 (backfilled with correct categories)
- Test coverage: +24 tests, +74 assertions

**Production Deployment Commands:**
```bash
# After deploying code changes, run on production:
bin/rails db:seed                                    # Add canonical categories
bin/rails categories:map_specific                    # Map specific → canonical
bin/rails comparisons:backfill_categories            # Fix comparison categories
bin/rails categories:generate_embeddings             # Generate embeddings
```

---

## ✅ COMPLETED: Phase 4.1b - Comprehensive Search & Admin Features (Nov 10, 2025)

**Status**: ✅ COMPLETE - Multi-field search with relevance scoring and admin refresh capability

**What Was Built:**

### 1. Comprehensive Multi-Field Search
- **Multi-field fuzzy search**: Searches across `user_query`, `technologies`, `problem_domains`, `architecture_patterns`, and associated `categories`
- **Synonym expansion**: 50+ mappings (e.g., "ruby" → ["rb", "ruby"], "auth" → ["auth", "authentication", "authorize", "authorization"])
- **PostgreSQL WORD_SIMILARITY**: Fuzzy matching with 0.45 threshold for partial matches
- **Weighted relevance scoring**:
  - user_query: 100 points (highest - user's exact words)
  - technologies: 50 points
  - problem_domains: 30 points
  - architecture_patterns: 20 points
  - categories: 10 points
- **GREATEST function**: Takes best score across synonym variations
- **Results ordered by relevance**: Best matches appear first (DESC order)

### 2. Database Schema Updates
- **Renamed fields** for consistency:
  - `tech_stack` → `technologies` (plural, stores multiple comma-separated values)
  - `problem_domain` → `problem_domains` (plural, stores multiple comma-separated values)
- **Added `architecture_patterns` column**: Now matches all three category types
- **GIN trigram indexes**: Added `gin_trgm_ops` indexes on all three searchable fields for performance
  - `index_comparisons_on_technologies_trgm`
  - `index_comparisons_on_problem_domains_trgm`
  - `index_comparisons_on_architecture_patterns_trgm`

### 3. Search Service Layer
- **SearchSynonymExpander** service (`app/services/search_synonym_expander.rb`):
  - 50+ synonym mappings for common technology terms
  - Handles abbreviations, variants, common misspellings
  - Returns expanded term array for comprehensive matching
  - Fully tested (14 tests, 61 assertions)

### 4. UI Improvements
- **Removed category dropdown**: Text search is now comprehensive enough
- **Preserved relevance scoring**: BrowseComparisonsPresenter no longer overrides search order with manual sort
- **Search-first UX**: When searching, relevance order takes precedence over "newest" or "popular" sorts

### 5. Admin Features
- **Admin refresh capability**: Admins can refresh comparisons in production
- **ComparisonPresenter** updated to:
  - Accept `current_user` parameter
  - Check `user&.admin?` for refresh authorization
  - Return `true` for admins or development mode, `false` otherwise
  - Prevent refresh of newly created comparisons (already fresh)

### 6. Testing & Validation
- **All tests passing**: 95 tests, 261 assertions, 0 failures
- **Comprehensive search validation**: 21/21 test queries return results
- **Real-world verification**: "rails state management" query puts Rails result at #1 (was at bottom)
- **System tests updated**: Removed category dropdown assertions

**Files Created:**
- `app/services/search_synonym_expander.rb` - Synonym expansion with 50+ mappings
- `db/migrate/20251110220247_rename_comparison_tech_stack_to_technologies_and_add_gin_indexes.rb`
- `test/services/search_synonym_expander_test.rb` - 14 comprehensive tests

**Files Modified:**
- `app/models/comparison.rb` - Added `search` scope with multi-field fuzzy search and relevance scoring
- `app/presenters/browse_comparisons_presenter.rb` - Preserve relevance scoring, skip sort override when searching
- `app/presenters/comparison_presenter.rb` - Admin refresh authorization with `current_user` parameter
- `app/controllers/comparisons_controller.rb` - Pass `current_user` to ComparisonPresenter
- `app/views/comparisons/index.html.erb` - Removed category dropdown
- `app/views/comparisons/show.html.erb` - Updated comment "Development & Admins"
- `lib/tasks/search.rake` - Updated field names, fixed `.count` → `.size` for custom SELECT queries
- `test/models/comparison_test.rb` - Updated all field name references
- `test/services/repository_comparer_test.rb` - Updated field name references
- `test/system/homepage_test.rb` - Removed category dropdown assertions

**Results:**
- Search "ruby" now finds 5 Rails comparisons (was 0)
- Search "rails state management" shows Rails result first (was last)
- Synonym expansion: "auth" finds authentication comparisons
- Fuzzy matching: "authentic" finds "authentication"
- Multi-field coverage: Searches all relevant fields + categories
- Performance: GIN indexes ensure fast fuzzy search on large datasets
- Admin control: Refresh button only visible to admins (not regular users)

**Success Criteria Met:**
- ✅ Multi-field search across all relevant comparison data
- ✅ Synonym expansion for common terms
- ✅ Fuzzy matching with PostgreSQL trigram similarity
- ✅ Relevance scoring puts best matches first
- ✅ GIN indexes for performance
- ✅ Simplified UI (no category dropdown needed)
- ✅ Admin refresh capability
- ✅ All tests passing

---

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

## 🚧 REMAINING: Phase 4.1b - Enhanced Categorization & Search

**Status**: 🔴 NEXT UP - Complete search improvements and UI enhancements

**What's Left** (from original Phase 4.1 plan):

### Remaining Work: Multi-Field Search & Browse UI (~2-3 hours)

**Goal**: Search across all relevant fields and build browsing interface

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
  - Admin link to /admin/jobs and /admin/stats (admin users only)
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
