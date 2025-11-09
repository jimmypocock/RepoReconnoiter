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

**Test Coverage**: 63 tests, 152 assertions, 0 failures ✅

**Completed Phases**:

- ✅ Phase 0: Initial Setup
- ✅ Phase 1: Core Foundation (GitHub API, Database, Models, Basic UI)
- ✅ Phase 2: AI Integration - Tier 1 Categorization
- ✅ Phase 3.5: AI Integration - Tier 3 Comparative Evaluation (MVP Core)
- ✅ Phase 3.6: Core Infrastructure Hardening
- ✅ Phase 3.8: Testing & Code Quality
- ✅ Phase 3.9: Production Stabilization & Bug Fixes
- ✅ Phase 3.7: Security & Deployment (Tasks 1-5D complete, 5A/5B/5E remaining)

---

## 🎯 CURRENT PRIORITY: Complete Phase 3.7 Production Verification

**Estimated Time**: 1 hour
**Status**: App is live and working, just needs final testing and documentation!

### Task 5A: User & Access Setup (10 mins)

- [x] Whitelist yourself as admin user via Render Shell

  ```bash
  # SSH into Render Shell, then run:
  bin/rails whitelist:add[jimmypocock]
  # The task automatically fetches GitHub ID and email from GitHub API
  ```

- [x] Add your GitHub ID to `MISSION_CONTROL_ADMIN_IDS` environment variable in Render

### Task 5B: Production Testing (45 mins)

- [x] Test OAuth flow (sign in with GitHub)
- [x] Create test comparison (verify full pipeline works)
- [x] Test daily sync job (`SyncTrendingRepositoriesJob`) via Mission Control
- [x] Test OpenAI API integration (verify cost tracking in database)
- [x] Check Mission Control Jobs dashboard at <https://reporeconnoiter.com/jobs>
- [x] Verify security headers at <https://securityheaders.com/>
- [x] Monitor Clarity analytics (verify tracking working)
- [x] Check Render logs for any errors

### Task 5E: Documentation (15 mins)

- [x] Update README.md with production URL
- [x] Document admin access setup in RENDER_DEPLOYMENT.md
- [x] Add "Known Issues" section if any issues discovered during testing

---

## 🚀 NEXT UP: Phase 4 - UI & Navigation Polish (MVP Completion)

**Goal**: Create a modern, browsable interface that showcases comparisons, categories, and trending repos.

**Priority**: This is the path to a polished, user-friendly MVP! 🎨

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
