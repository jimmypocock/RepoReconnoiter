# Future Enhancements (Post-MVP)

These are features to consider after the MVP is complete and stable in production.

---

## Enhanced Admin Features

### Enhanced Cost Tracking (Optional Future Enhancements)

**Note**: Basic enhanced cost dashboard has been moved to `TODO.md` Phase 5. Items below are optional extras.

- [ ] Implement hard spending cap enforcement
  - Check total monthly spend before allowing new comparisons
  - If over budget, show message to users
  - Admins can override budget limit
  - Log budget limit hits for monitoring
- [ ] Budget alert notifications
  - Email admin when spend reaches 50%, 75%, 90% of monthly budget
  - Slack/Discord webhook integration for real-time alerts

### Waitlist/Access Request System (Future Enhancement)

**Note**: Basic whitelist management has been moved to `TODO.md` Phase 5. Items below are optional enhancements.

- [ ] Waitlist/access request system
  - Shown to non-whitelisted authenticated users
  - "Request Access" button (records interest)
  - Admin approval workflow
- [ ] Email notifications for whitelist approvals
  - Notify user when whitelisted (via Action Mailer)
  - Welcome email with getting started guide

### Audit Logging (Optional Enhancement)

**Note**: Consider if needed after observing production usage patterns.

- [ ] Create audit_logs table for structured logging
  - Track user actions (sign in, comparison created, whitelist changes)
  - Store metadata (IP address, user agent, timestamps)
- [ ] Admin audit log viewer (`/admin/audit_logs`)
  - Searchable, filterable log viewer
  - Filter by user, action, resource, date range
  - Export to CSV for analysis

---

## User Profile & Dashboard

**Note**: Basic user profile page has been moved to `TODO.md` Phase 5. Items below are advanced personalization features.

### User Personalization (Future Enhancement)

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

**Note**: Most UI/UX polish items have been moved to `TODO_UI.md` for V1 implementation. Items below are post-V1 enhancements.

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
