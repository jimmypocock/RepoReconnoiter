# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RepoReconnoiter is an Open Source Intelligence Dashboard that analyzes GitHub trending repositories using AI to provide developers with context-aware recommendations. The system fetches trending repos every 20 minutes, uses AI to categorize and analyze them, and helps developers discover relevant tools based on their tech stack.

## Tech Stack

- **Framework**: Rails 8.1 with Hotwire/Turbo + Stimulus
- **Database**: PostgreSQL
- **Background Jobs**: Solid Queue (database-backed, no Redis needed)
- **Job Scheduling**: Solid Queue recurring tasks (see `config/recurring.yml`)
- **AI Provider**: OpenAI (gpt-4o-mini for categorization, gpt-4o for deep dives)
- **Deployment**: Kamal (containerized deployment)
- **Styling**: Tailwind CSS
- **Ruby Version**: 3.4.7

## Development Commands

### Setup
```bash
bin/setup                 # Initial setup: install dependencies, setup database
bin/dev                   # Start development server (runs Puma + Solid Queue + Tailwind watcher)
```

### Database
```bash
bin/rails db:create       # Create database
bin/rails db:migrate      # Run migrations
bin/rails db:seed         # Seed database (populates initial categories)
bin/rails db:reset        # Drop, create, migrate, and seed database
```

### Testing
```bash
bin/rails test            # Run all tests
bin/rails test:system     # Run system tests
bin/rails test test/models/repository_test.rb  # Run specific test file
```

### Linting & Security
```bash
bin/rubocop               # Run RuboCop linter
bin/brakeman              # Run security vulnerability scanner
bin/bundler-audit         # Check for vulnerable gem versions
```

### Background Jobs
```bash
bin/rails solid_queue:start    # Start Solid Queue worker
bin/rails solid_queue:stop     # Stop Solid Queue worker
```

### Deployment
```bash
bin/kamal deploy          # Deploy to production servers
bin/kamal console         # Open Rails console on production
bin/kamal logs            # Tail production logs
bin/kamal shell           # SSH into production container
```

## Architecture Overview

### Data Flow

1. **GitHub API Sync**: Solid Queue recurring job fetches trending repos from GitHub API
2. **Tier 1 Processing (Cheap)**: gpt-4o-mini categorizes repos using metadata + description
3. **Tier 2 Processing (Expensive)**: gpt-4o performs deep analysis on-demand (README + issues)
4. **Caching Strategy**: Aggressive caching to minimize AI API costs - repos only re-analyzed if README changes or significant activity detected

### Database Schema (from OVERVIEW.md)

- **repositories**: Stores GitHub repo data, cached README content, and metadata
- **ai_analyses**: Versioned AI-generated insights with cost tracking (tracks tokens, model used, USD cost)
- **categories**: AI-generated categorization taxonomy (Problem Domain, Architecture Pattern, Maturity Level)
- **repository_categories**: Many-to-many join with confidence scores
- **github_issues**: Cached issues for quality signal analysis
- **analysis_queue**: Queue for batch processing AI analysis jobs
- **cost_tracking**: Daily rollup of AI API spending
- **trends**: Aggregate trend data computed periodically

### Cost Optimization Strategy

The app implements several strategies to keep AI API costs under $10/month:

1. **Selective Processing**: Only analyze repos that pass metadata filters (stars > 100, active within 30 days, relevant language)
2. **Tiered AI Models**: Use cheap models (gpt-4o-mini ~$0.001/repo) for categorization, expensive models only for deep dives
3. **Aggressive Caching**: Track `readme_sha` to detect changes; don't re-analyze unless content changed or 7+ days passed
4. **Batch Processing**: Queue repos during the day, process in nightly batches (limit 50/day)
5. **User-Pays Model**: Free tier has basic features, Pro tier ($5/month) unlocks AI-powered insights

### Key Model Methods Pattern

Models should implement smart caching logic:

```ruby
class Repository < ApplicationRecord
  def needs_analysis?
    return true if last_analyzed_at.nil?
    return true if readme_changed?
    return true if last_analyzed_at < 7.days.ago
    return true if stargazers_count > last_analysis.stargazers_at_analysis * 1.5
    false
  end

  def readme_changed?
    current_sha != readme_sha
  end
end
```

### Background Job Pattern

Jobs should track costs and implement rate limiting:

```ruby
class AnalyzeRepositoryJob < ApplicationJob
  queue_as :default

  def perform(repository_id)
    repo = Repository.find(repository_id)
    return unless repo.needs_analysis?

    result = OpenAiService.analyze(repo, model: "gpt-4o-mini")

    # Store analysis with cost tracking
    repo.ai_analyses.create!(
      summary: result[:summary],
      input_tokens: result[:usage][:input_tokens],
      output_tokens: result[:usage][:output_tokens],
      cost_usd: calculate_cost(result[:usage]),
      model_used: "gpt-4o-mini"
    )
  end
end
```

## Rails 8 Specific Features

- **Solid Queue**: Database-backed job processing (no Redis required). Job queues configured in `config/queue.yml`
- **Solid Cache**: Database-backed caching configured in `config/cache.yml`
- **Solid Cable**: Database-backed Action Cable for WebSocket connections
- **Thruster**: HTTP asset caching/compression (runs in production via Dockerfile)
- **Kamal**: Zero-downtime deployments with Docker containers (config in `config/deploy.yml`)

## Configuration Files

- `config/deploy.yml`: Kamal deployment configuration (servers, registry, environment variables)
- `config/recurring.yml`: Solid Queue recurring task definitions for scheduled jobs
- `config/queue.yml`: Solid Queue configuration
- `OVERVIEW.md`: Detailed project concept, database schema, and cost optimization strategies
- `PLAN.md`: Phased build order from foundation to deployment
