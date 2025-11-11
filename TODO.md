# RepoReconnoiter - TODO List

Track progress towards API-ready backend and Next.js rebuild.

## Status Legend

- [ ] Not started
- [x] Complete
- [~] In progress

---

## 🎯 CURRENT STATUS (Updated: Nov 11, 2025)

### ✅ Rails Prototype COMPLETE - Ready for API Pivot

**Deployment**: <https://reporeconnoiter.com> (Render Standard Plan - 2GB RAM)

**What's Working (Backend - Ready to become API)**:

- ✅ User authentication (GitHub OAuth with whitelist)
- ✅ Admin system (User.admin? checks, whitelist management)
- ✅ AI-powered comparisons (multi-query GitHub search + OpenAI analysis)
- ✅ Background jobs (Solid Queue via Puma plugin)
- ✅ Real-time progress (ActionCable/Solid Cable for comparison creation)
- ✅ Recurring tasks (daily trending sync at 3am, hourly cleanup)
- ✅ Rate limiting (25/day per user, 5/day per IP via Rack::Attack)
- ✅ Security hardening (CSP, prompt injection defense, security headers)
- ✅ Cost tracking (automatic AI spend monitoring via AiCost model)
- ✅ CI/CD (GitHub Actions + local ci:all task)
- ✅ Custom domain with SSL
- ✅ Mission Control Jobs dashboard (/admin/jobs)
- ✅ Category system with 129 canonical categories (tech, problem domains, architecture patterns)
- ✅ Three-layer category matching (aliases, fuzzy matching, semantic embeddings)
- ✅ Comprehensive multi-field search (fuzzy matching, synonym expansion, relevance scoring)
- ✅ Repository deep analysis (AnalysisDeep model with gpt-5)
- ✅ Rails UI prototype (tab-based interface, empty states, progress modals, cross-linking)

**Test Coverage**: 95 tests, 261 assertions, 0 failures ✅

**GitHub API Compliance**: ✅ VERIFIED
- Using authenticated API (5,000 requests/hour limit, well under usage)
- Public data only (search, metadata, READMEs)
- Adding value via AI analysis (not just mirroring GitHub data)
- Compliant with GitHub Terms of Service Section H

---

## 🎯 CURRENT PRIORITY: API Prep Phase (Backend Hardening)

**Goal**: Harden backend before converting to API-only service

**Status**: 🟡 READY TO START

**Estimated Time**: 6-8 hours (thorough, security-focused)

**⚠️ CRITICAL**: See `TODO_API_PREP.md` for detailed security-first implementation plan

**Why Thorough Prep Matters**: A single bad actor could cost $100+ in OpenAI bills in minutes. We need bulletproof auth, authorization, and rate limiting.

### Phase API-1: Critical Test Coverage (~3-4 hours)

**Why**: These tests become your API contract tests when you build the REST API

#### High Priority (Must Have):
- [ ] **User.admin? tests** (5 tests, 30 min)
  - Test admin authorization logic (used for API admin endpoints)
  - Test ALLOWED_ADMIN_GITHUB_IDS env parsing
  - Test edge cases (nil, empty string, invalid IDs)
  - File: `test/models/user_test.rb`

- [ ] **SearchComparisonsPresenter tests** (10 tests, 1 hour)
  - Test search with filters (date, sort)
  - Test has_filters? logic
  - Test presenter builds correct scope
  - File: `test/presenters/search_comparisons_presenter_test.rb`

- [ ] **ComparisonsController tests** (10 tests, 1.5 hours)
  - Test index with/without filters
  - Test create with valid/invalid params
  - Test show with valid/invalid comparison IDs
  - Test rate limiting enforcement
  - Test admin refresh capability
  - File: `test/controllers/comparisons_controller_test.rb`

#### Medium Priority (Nice to Have):
- [ ] **ComparisonPresenter tests** (5 tests, 30 min)
  - Test can_refresh? logic (admins, dev mode, newly created)
  - Test current_user parameter handling
  - File: `test/presenters/comparison_presenter_test.rb`

- [ ] **Search enhancement tests** (8 tests, 1 hour)
  - Test synonym expansion (SearchSynonymExpander already has 14 tests ✅)
  - Test fuzzy matching with WORD_SIMILARITY
  - Test relevance scoring order
  - File: `test/models/comparison_test.rb` (add to search scope tests)

#### Low Priority (Skip for Now):
- [ ] ~~Repository analyzer tests~~ (defer - complex, working in production)
- [ ] ~~Deep analysis tests~~ (defer - complex, working in production)

**Total**: ~20 high-priority tests, ~3-4 hours

### Phase API-2: User Profile Backend (~1 hour)

**Why**: These become `/api/v1/users/me` endpoints

- [ ] Add `User#comparisons_count_this_month` method
- [ ] Add `User#analyses_count_this_month` method
- [ ] Add `User#remaining_comparisons_today` method (already have helper, make model method)
- [ ] Add `User#total_ai_cost_spent` method (aggregate from AiCost)
- [ ] Add account deletion logic (`User#soft_delete` or `User#destroy_with_cascade`)
- [ ] Test all new User model methods (5 tests)

**Files**:
- `app/models/user.rb` - Add methods
- `test/models/user_test.rb` - Add tests

### Phase API-3: Verify Admin Backend (~30 min)

**Why**: Ensure admin endpoints work before exposing as API

- [ ] Verify `Admin::UsersController` works (created by other Claude instance)
- [ ] Verify `Admin::StatsController` works (created by other Claude instance)
- [ ] Test admin authorization (only admins can access)
- [ ] Test whitelist CRUD operations
- [ ] Document admin endpoints for API

**Files to Review**:
- `app/controllers/admin/users_controller.rb`
- `app/controllers/admin/stats_controller.rb`
- `test/controllers/admin/users_controller_test.rb`
- `test/controllers/admin/stats_controller_test.rb`

---

## 🚀 NEXT: API + Next.js Rebuild

**After API Prep is complete, we will:**

1. **Design REST API** (~2-3 hours)
   - Define endpoints (`/api/v1/comparisons`, `/api/v1/repositories`, etc.)
   - Authentication strategy (JWT tokens vs session cookies)
   - Rate limiting for API (same as web? different tiers?)
   - CORS configuration for Next.js frontend
   - API documentation (OpenAPI/Swagger)

2. **Build API Controllers** (~4-6 hours)
   - Namespace under `app/controllers/api/v1/`
   - Convert existing controllers to API format (JSON responses)
   - Add API authentication (Devise token auth or JWT)
   - Test all API endpoints

3. **Setup Next.js Frontend** (~8-12 hours)
   - Initialize Next.js project (App Router)
   - Setup Vercel deployment
   - Build "blossoming" UI you envisioned
   - Connect to Rails API
   - Real-time progress via WebSockets

4. **Deploy Both**
   - Rails API on Render (existing setup, just remove views)
   - Next.js on Vercel (new)
   - Configure CORS and authentication

**Rails becomes**: API-only backend (no views, just JSON responses)
**Next.js becomes**: Beautiful frontend with your vision (blossoming UI, smooth animations)

---

## 📋 Completed Phases (Archive)

<details>
<summary>Phase 0-3: Core Foundation & MVP (Click to expand)</summary>

- ✅ Phase 0: Initial Setup
- ✅ Phase 1: Core Foundation (GitHub API, Database, Models, Basic UI)
- ✅ Phase 2: AI Integration - Tier 1 Categorization
- ✅ Phase 3.5: AI Integration - Tier 3 Comparative Evaluation (MVP Core)
- ✅ Phase 3.6: Core Infrastructure Hardening
- ✅ Phase 3.7: Security & Deployment
- ✅ Phase 3.8: Testing & Code Quality
- ✅ Phase 3.9: Production Stabilization & Bug Fixes
- ✅ Phase 3.10: Search Quality & Relevance (Nov 9, 2025)

See `docs/TODO/PHASE_*.md` for detailed history.

</details>

<details>
<summary>Phase 4: Polish & Admin Features (Click to expand)</summary>

- ✅ Phase 4.0: Comparison Creation Progress UX (Nov 9, 2025) - Real-time ActionCable progress
- ✅ Phase 4.1a: Category Infrastructure & Cleanup (Nov 10, 2025) - 129 canonical categories
- ✅ Phase 4.1b: Comprehensive Search & Admin Features (Nov 10, 2025) - Multi-field fuzzy search
- ✅ Phase 4.3: Rails UI Prototype (Nov 11, 2025) - Tab-based interface, complete
- ✅ Phase 4.4: Admin Features (Nov 11, 2025) - User management, stats dashboard (via parallel Claude)

**Rails UI Prototype Details**:
- Tab-based interface (Comparisons + Analyses tabs)
- Hero section with dual CTAs
- Cross-linking between comparisons and analyses
- Empty states with actionable CTAs
- Quick action bar (desktop + mobile FAB)
- Rate limit counter (color-coded by usage)
- Progress modals with real-time updates
- Repository decorator pattern
- Clean, professional UI ready as spec for Next.js rebuild

</details>

---

## 📝 Notes

**Phase History**: See `docs/TODO/PHASE_*.md` for detailed history and learnings from completed phases.

**Future Enhancements**: See `docs/TODO/FUTURE.md` for post-API features (user personalization, trend analysis, advanced features).

**Security Documentation**: See `docs/SECURITY_REVIEW.md` for comprehensive security audit summary.

**Deployment Guide**: See `docs/RENDER_DEPLOYMENT.md` for complete deployment instructions.

**Rails Prototype**: Serves as functional spec for Next.js rebuild. All business logic, data flows, and user journeys validated.
