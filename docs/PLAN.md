# Plan

Confirmed Tech Stack

- Framework: Rails 8 (with Hotwire/Turbo + Stimulus)
- Database: PostgreSQL
- Background Jobs: Solid Queue (database-backed, no Redis needed)
- Job Scheduling: Solid Queue recurring tasks (replaces sidekiq-cron/whenever)
- AI Provider: OpenAI (gpt-5-mini for categorization, gpt-5 for deep dives)
- Deployment: Render (just Rails web service + PostgreSQL)
- Data Source: GitHub API trending repos (~50/day)
- Auth: None initially, Sign In With GitHub on future roadmap

  Proposed Build Order

  Phase 1: Core Foundation

  1. Generate new Rails 8 app with solid_queue
  2. Set up database schema from OVERVIEW.md (repositories, ai_analyses, categories, etc.)
  3. Seed initial categories from OVERVIEW.md
  4. GitHub API service to fetch trending repos
  5. Basic Solid Queue job to sync trending repos daily
  6. Simple index page showing raw repo data

  Phase 2: AI Tier 1 - Categorization

  7. OpenAI API wrapper with token/cost tracking
  8. Tier 1 job: Basic categorization with gpt-5-mini
  9. Smart caching logic (don't re-analyze unchanged repos)
  10. Display categorized repos on dashboard with filters
  11. Admin UI for approving/denying AI-suggested categories

  Phase 3: AI Tier 2 - Deep Dives

  12. Tier 2 job: Deep analysis with gpt-5 (on-demand)
  13. README + issues analysis
  14. Cost tracking dashboard
  15. Rate limiting & budget guards

  Phase 4: Polish & Deploy

  16. Hotwire real-time updates for new repos
  17. Configure render.yaml for deployment
  18. Deploy to Render
