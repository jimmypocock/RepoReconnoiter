# Future Enhancements (Post-MVP)

These are features to consider after the MVP is complete and stable in production.

---

## Enhanced Admin Features

### Cost Tracking Dashboard

**Status**: Basic admin stats exist (total AI spend visible on homepage). This section describes an enhanced, detailed dashboard.

- [ ] Admin cost dashboard page (`/admin/costs`)
  - Total spend today, this week, this month
  - Spend by user (top 10 users leaderboard)
  - Spend by model (gpt-5 vs gpt-5-mini breakdown)
  - Daily spend chart (last 30 days visualization)
  - Budget status: "$X.XX / $10.00 monthly budget" with progress bar
  - Alert banner if approaching limit (>$8.00/month)
- [ ] Implement spending cap enforcement
  - Check total monthly spend before allowing new comparisons
  - If over budget, show message to users
  - Admins can override budget limit
  - Log budget limit hits for monitoring
- [ ] Budget alert notifications
  - Email admin when spend reaches 50%, 75%, 90% of monthly budget
  - Slack/Discord webhook integration for real-time alerts

### Enhanced Whitelist Management

- [ ] Admin interface for whitelist management (`/admin/users`)
  - List all users with whitelist status
  - Filter: whitelisted, pending, all
  - Bulk actions: "Whitelist selected users"
  - Individual actions: Whitelist, Remove access, Make admin
  - Show user's GitHub profile, comparisons count, cost spent
- [ ] Waitlist/access request system
  - Shown to non-whitelisted authenticated users
  - "Request Access" button (records interest)
  - Admin approval workflow
- [ ] Email notifications for whitelist approvals
  - Notify user when whitelisted (via Action Mailer)
  - Welcome email with getting started guide

### Audit Logging

- [ ] Create audit_logs table for structured logging
  - Track user actions (sign in, comparison created, whitelist changes)
  - Store metadata (IP address, user agent, timestamps)
- [ ] Admin audit log viewer (`/admin/audit_logs`)
  - Searchable, filterable log viewer
  - Filter by user, action, resource, date range
  - Export to CSV for analysis

---

## Tier 2 Deep Analysis (AI-Powered README & Issues Analysis)

**Status**: Deferred post-MVP. Tier 1 (categorization) and Tier 3 (comparison) are working well. Tier 2 adds expensive deep-dive analysis.

**Cost**: ~$0.05-0.10 per repository (10-20x more expensive than Tier 1)

### Database Schema

- [ ] **OPTIONAL**: Create `github_issues` table
  - **Note**: May not be needed - can link directly to GitHub issues instead
  - Alternative: Fetch issues on-demand via API (no storage)
  - Decision: TBD during implementation based on value vs maintenance cost

### Deep Analysis Features

- [ ] Create `DeepAnalyzeRepositoryJob` (uses gpt-5)
- [ ] Fetch README content from GitHub
- [ ] Fetch recent issues (last 30 days) - either store or analyze on-the-fly
- [ ] Implement comprehensive analysis prompt
  - What problem does it solve?
  - Who is it for?
  - Quality signals from issues
  - Learning opportunities
  - Production readiness assessment
- [ ] Store rich analysis data in `analyses` table (tier2 type)
- [ ] Add expiration logic (cache for 30 days)

### On-Demand Analysis UI

- [ ] Add "Deep Analyze" button to repository cards
- [ ] Queue analysis job when button clicked
- [ ] Show loading state with Turbo Streams
- [ ] Display deep analysis results in modal or expanded view
- [ ] Rate limit: 3 deep dives per day for free tier
- [ ] Add visual diff between Tier 1 and Tier 2 insights

### Budget Controls for Tier 2

- [ ] Implement daily spending cap for Tier 2 ($0.50/day max)
- [ ] Pause analysis jobs if budget exceeded
- [ ] Send alerts when approaching limits
- [ ] Admin emergency "pause all Tier 2 AI" switch

---

## User Profile & Dashboard

**Status**: Basic user authentication exists via Devise + GitHub OAuth. This section describes a full user dashboard experience.

### User Profile Page

- [ ] Create `users#show` route and action (current user only)
- [ ] My Comparisons section
  - List of user's comparisons with quick filters
  - Edit/delete options
  - Re-run with fresh data button
  - Export to CSV/JSON
- [ ] Usage Stats section
  - Comparisons this month (chart/graph)
  - AI cost spent (if admin)
  - Rate limit status (X/25 comparisons today with visual indicator)
  - Historical usage trends
- [ ] Account Settings section
  - GitHub profile info (read-only display)
  - Email notification preferences
  - Delete account option with confirmation
- [ ] Admin section (admin users only)
  - Quick link to Mission Control Jobs dashboard
  - Quick link to enhanced cost tracking dashboard
  - Quick link to whitelist management
  - System health indicators

### User Personalization

- [ ] Create user preferences (tech stack, interests)
- [ ] Personalized recommendations based on user stack
- [ ] User bookmarks and notes on repositories
- [ ] Weekly email digest of relevant repos
- [ ] Comparison history with smart suggestions
- [ ] Saved searches and alerts

## Trend Analysis

- [ ] Create `Trend` model and aggregation jobs
- [ ] Detect rising technologies (e.g., "Vector databases up 200%")
- [ ] Pattern recognition across repos
- [ ] Weekly trend report generation
- [ ] Visualization of technology adoption over time

## Comparison Relationship Analysis

**Status**: Enhancement to ComparisonRepository join table to track richer context about how repositories relate within a specific comparison.

**Current State**: ComparisonRepository only stores `rank` and `score` - minimal metadata about the relationship.

**Proposed Enhancement**:

- [ ] Add `alternatives_mentioned` field (jsonb) to ComparisonRepository
  - Store other tool names mentioned when discussing this repo
  - Example: When comparing Sidekiq, might mention "Resque", "DelayedJob", "GoodJob"
  - Enables "Users also considered..." recommendations
  - AI can extract these during comparison generation
- [ ] Add `ecosystem_position` field (text) to ComparisonRepository
  - Brief description of where this repo fits relative to others in THIS comparison
  - Example: "Most popular, battle-tested option" or "Newer, simpler alternative"
  - Context-aware: same repo might have different positions in different comparisons
  - Enables more nuanced comparison cards and explanations
- [ ] Update comparison creation prompt to extract this data
  - Add structured output format for these new fields
  - No additional API calls needed (extract from existing comparison analysis)
- [ ] Display relationship data in comparison cards
  - Show "Position: X" badge or inline text
  - "Also mentioned: Y, Z" pills below repo name
  - Helps users understand the comparison landscape at a glance

**Benefits**:
- Richer comparison context without extra AI cost
- Better user understanding of how tools relate
- Foundation for recommendation engine
- Enables ecosystem visualization features later

## UI/UX Polish

### Skeleton Loaders for Infinite Scroll

- [ ] Add skeleton loading states for pagination
  - Show 2-3 pulsing gray card skeletons when loading next page
  - Remove skeletons when real content arrives via Turbo Stream
  - Provides visual feedback that content is loading (like Facebook/Twitter)
  - Pure CSS + HTML (no React needed)
  - **Note**: Basic skeleton loaders are in `TODO_UI.md` Phase 2 for tab content loading

### Global Search (Cross-Tab Search)

**Status**: V3 feature, deferred from V1 tab-based UI restructure

- [ ] Unified search bar that searches both Comparisons AND Analyses
- [ ] Results grouped by type with clear visual separation
- [ ] Tab context preserved (e.g., search from Comparisons shows Comparison results first)
- [ ] Advanced filters: "Search in: All | Comparisons | Analyses"
- [ ] Performance optimization: Index both tables for fast cross-table search

**Why Deferred**:
- V1 focuses on tab-specific search (simpler, easier to understand)
- Global search requires more complex UI (grouped results, context switching)
- Need to validate that users want this feature before building
- Can add in V3 after observing user behavior in V1/V2

### Save/Star Functionality

**Status**: V2 feature, deferred from V1 tab-based UI restructure

- [ ] Star/bookmark comparisons and analyses
- [ ] "My Starred" filter on each tab
- [ ] Personal collections: group related items together
- [ ] Export starred items as CSV/JSON
- [ ] Email digest: weekly summary of starred items with updates

**Why Deferred**:
- V1 focuses on core discovery and comparison features
- Starring requires additional UI elements (star icons, filters, collections page)
- Can add in V2 once users have built up comparison/analysis history
- Low friction to add later (non-breaking change)

## Advanced Features

- [ ] Alternative/cheaper AI providers (Gemini Flash, Claude)
- [ ] Pro tier subscription ($5/month for unlimited comparisons + Tier 2 access)
- [ ] API for external integrations
- [ ] Browser extension for GitHub
- [ ] Slack/Discord integration for team notifications

---

## Notes

These features are intentionally deferred to keep the MVP scope tight and focused on the core value proposition: AI-powered GitHub tool comparisons for developers.

**Priority**: Focus on Phase 4 UI/UX polish first. Only consider these enhancements after MVP is launched and validated with real users.
