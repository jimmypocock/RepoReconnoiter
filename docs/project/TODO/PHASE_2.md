# Phase 2: AI Integration - Tier 1 (Categorization)

## OpenAI API Setup

- [x] Add OpenAI gem to Gemfile
- [x] Create `OpenAi` wrapper (`app/services/open_ai.rb`) - transparent wrapper with automatic cost tracking
- [x] Implement token counting and cost calculation
- [x] Add API key configuration (credentials)
- [x] Create cost tracking helpers
- [x] Test API connection with simple prompt
- [x] Model whitelisting (only gpt-5-mini and gpt-5 with explicit pricing)
- [x] Automatic daily rollup to `ai_costs` table
- [x] All services use `OpenAi` instead of calling OpenAI directly

## Seed Categories

- [x] Create seeds file with Problem Domain categories
  - Authentication & Identity, Data Sync, Rate Limiting, Background Jobs, etc.
- [x] Create seeds for Maturity Level categories
  - Experimental, Active Development, Production Ready, Enterprise Grade, Abandoned
- [x] Create seeds for Architecture Pattern categories
  - Microservices, Event-driven, Serverless-friendly, Monolith utilities
- [x] Run `bin/rails db:seed` and verify categories

## AI Categorization Job (Tier 1 - Cheap)

- [x] Create `AnalyzeRepositoryJob` (uses gpt-5-mini via `OpenAi` service)
- [x] Create `RepositoryAnalyzer` service (`app/services/repository_analyzer.rb`)
- [x] Create `Prompter` service for AI prompt template rendering (`app/prompts/`)
- [x] Implement prompt for quick categorization
- [x] Parse AI response and assign categories
- [x] Store analysis with token/cost tracking in `analyses`
- [x] Link categories to repository via `repository_categories`
- [x] Add confidence scoring (0.0-1.0)
- [x] Implement smart duplicate detection (auto-create new categories intelligently)
- [x] All models organized with consistent code structure (Public Instance → Class → Private)
- [x] Implement smart caching logic (`Repository#needs_analysis?`)

## Filtering & Display

- [x] Add category filter UI to dashboard
- [x] Display AI-assigned categories on each repo card
- [x] Show category badges with color coding (blue=problem, purple=architecture, green=maturity)
- [x] Display confidence scores as percentages on badges
- [x] Display last analyzed timestamp

## Cost Monitoring

- [x] Automatic cost tracking via `OpenAi` service wrapper (Phase 2 complete)
- [x] Daily rollup to `ai_costs` table with 6 decimal precision (Phase 3.5)
- [x] Admin stats bar on homepage shows total AI spend (Phase 3.8)

---
