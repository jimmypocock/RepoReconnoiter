# Phase 1: Core Foundation

## GitHub API Integration

- [x] Add Octokit gem to Gemfile
- [x] Store GitHub personal access token in Rails credentials
- [x] Create `Github` API wrapper (`app/services/github.rb`) - follows "Doer" naming pattern
  - [x] Implement search repositories (using Search API)
  - [x] Implement search trending repositories
  - [x] Implement repository details endpoint (README, metadata)
  - [x] Implement issues endpoint (for quality signals)
  - [x] Add rate limit tracking and handling
  - [x] Add authentication with GitHub token
  - [x] Support both instance and class methods via delegation
- [x] Build GitHub API explorer rake task (`lib/tasks/github.rake`)
  - [x] Fetch and display sample trending repos
  - [x] Print available fields and data structure
  - [x] Verify what metadata GitHub actually provides

## Database Schema

- [x] Design migrations based on actual GitHub API data structure (see SCHEMA.md)
- [x] Create `repositories` table with GitHub metadata fields
- [x] Create `analyses` table for AI-generated insights (renamed from `ai_analyses`)
- [x] Create `categories` table for categorization taxonomy
- [x] Create `repository_categories` join table
- [x] Create `queued_analyses` table for batch processing (renamed from `analysis_queue`)
- [x] Create `ai_costs` table for AI spending monitoring (renamed from `cost_tracking`)
- [x] Run migrations and verify schema

## Models & Validations

- [x] Create `Repository` model with associations and validations
- [x] Create `Analysis` model with cost tracking methods (renamed from `AiAnalysis`)
- [x] Create `Category` model with slug generation
- [x] Create `RepositoryCategory` model
- [x] Create `QueuedAnalysis` model with status enum (renamed from `AnalysisQueue`)
- [x] Create `AiCost` model with aggregation methods (renamed from `CostTracking`)
- [x] Add model tests for key business logic (completed in Phase 3.8)

## Basic UI & Data Display

- [x] Create repositories controller and index view
- [x] Create basic dashboard showing categorized repo data
- [x] Add Pagy pagination (20 repos per page)
- [x] Style with Tailwind CSS
- [x] Set root route to repositories#index (later changed to comparisons#index in Phase 3.5)
- [x] Add category filtering by type
- [x] Display AI summaries and confidence scores

## Background Jobs - GitHub Sync

- [x] Create `SyncTrendingRepositoriesJob`
- [x] Configure Solid Queue recurring task in `config/recurring.yml`
- [x] Test job execution manually
- [x] Add error handling and retry logic
- **Note**: Daily sync configured for production. MVP focuses on user-driven comparisons as primary feature.
