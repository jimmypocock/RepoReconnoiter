# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RepoReconnoiter is an Open Source Intelligence Dashboard that analyzes GitHub trending repositories using AI to provide developers with context-aware recommendations. The system fetches trending repos every 20 minutes, uses AI to categorize and analyze them, and helps developers discover relevant tools based on their tech stack.

## Core Principles

1. **Cost Control**: Keep AI API costs under $10/month through automatic tracking, caching, and smart model selection
2. **Code Consistency**: All code follows strict organization standards with alphabetized methods and clear section headers
3. **Service Pattern**: Use "Doer" naming (no "Service" suffix) for all service classes
4. **Automatic Tracking**: The `OpenAi` service automatically tracks all API costs - never call OpenAI directly
5. **Prompt as Code**: AI prompts are versioned ERB templates in `app/prompts/`, not hardcoded strings
6. **Multi-Query Strategy**: Use 2-3 GitHub queries for comprehensive results when needed

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

# AI Analysis Testing
bin/rails analyze:compare["query"]         # Test full comparison pipeline (parse → search → merge)
bin/rails analyze:validate_queries         # Run test suite with sample queries
bin/rails analyze:repo[owner/name]         # Test Tier 1 analysis on single repo
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

## Code Organization Standards

All services and models MUST follow this consistent structure:

### Service/Model Organization

```ruby
class ExampleService
  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def initialize
    # initialization logic
  end

  def method_a
    # Methods alphabetized within this section
  end

  def method_b
    # ...
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Use 'class << self' - NOT 'def self.method_name'

    def class_method_a
      # Methods alphabetized within this section
    end

    def class_method_b
      # ...
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def private_method_a
    # Methods alphabetized within this section
  end

  def private_method_b
    # ...
  end
end
```

### Key Rules

1. **Section Order**: Public instance methods → Class methods → Private methods
2. **Class Methods**: ALWAYS use `class << self`, NEVER use `def self.method_name`
3. **Alphabetization**: Methods MUST be alphabetized within each section (except `initialize` which comes first)
4. **Headers**: Use `#--------------------------------------` separators with section names
5. **Models**: Same rules apply - ASSOCIATIONS, VALIDATIONS, CALLBACKS, SCOPES, then methods

## Service Naming Convention ("Doer" Pattern)

Services use action-oriented names WITHOUT "Service" suffix:

- ✅ `Prompter` (renders AI prompts)
- ✅ `UserQueryParser` (parses user queries)
- ✅ `RepositoryAnalyzer` (analyzes repositories)
- ✅ `Github` (GitHub API wrapper)
- ✅ `OpenAi` (OpenAI API wrapper)
- ❌ ~~`PromptService`~~ (too verbose)
- ❌ ~~`QueryParserService`~~ (too verbose)

## Architecture Overview

### Data Flow

1. **GitHub API Sync**: Solid Queue recurring job fetches trending repos from GitHub API
2. **Tier 1 Processing (Cheap)**: gpt-4o-mini categorizes repos using metadata + description
3. **Tier 2 Processing (Expensive)**: gpt-4o performs deep analysis on-demand (README + issues)
4. **Tier 3 Processing (Comparison)**: Multi-query GitHub search, merge/dedupe, AI-powered comparison
5. **Caching Strategy**: Aggressive caching to minimize AI API costs - repos only re-analyzed if README changes or significant activity detected

### Core Services

#### OpenAi Service (`app/services/open_ai.rb`)

Transparent wrapper for OpenAI API that automatically tracks costs and enforces model whitelisting.

**Key Features:**
- **Model Whitelisting**: Only allows `gpt-4o-mini` and `gpt-4o` with explicit pricing
- **Automatic Cost Tracking**: Every API call updates `ai_costs` table with daily rollup
- **Transparent API**: Returns same response object as `OpenAI::Client`
- **Usage Tracking**: Logs model, tokens, and cost for every request

```ruby
# Always use OpenAi service instead of calling OpenAI directly
ai = OpenAi.new
response = ai.chat(
  messages: [
    { role: "system", content: "You are a helpful assistant" },
    { role: "user", content: "Hello!" }
  ],
  model: "gpt-4o-mini",
  temperature: 0.3,
  track_as: "description_of_what_this_does"  # Optional: helps with debugging
)

# Response is standard OpenAI::Client response
content = response.choices[0].message.content
tokens = response.usage.prompt_tokens
```

**Pricing (as of 2025):**
- `gpt-4o-mini`: $0.150/1M input, $0.600/1M output
- `gpt-4o`: $2.50/1M input, $10.00/1M output

#### Prompter Service (`app/services/prompter.rb`)

Renders AI prompt templates from `app/prompts/` directory using ERB.

**Key Features:**
- **Template Rendering**: Renders `.erb` files with variable interpolation
- **Prompt Injection Prevention**: `sanitize_user_input()` method prevents attacks
- **Convention**: System prompts end in `_system.erb`, user prompts in other names

```ruby
# Render a system prompt (no variables)
system_prompt = Prompter.render("user_query_parser_system")

# Render with variables
user_prompt = Prompter.render("repository_analyzer_build",
  repository: repo,
  available_categories: categories
)

# Sanitize user input to prevent prompt injection
safe_query = Prompter.sanitize_user_input(user_input)
```

**Prompt Directory Structure:**
```
app/prompts/
  ├── README.md                              # Documentation
  ├── user_query_parser_system.erb           # System prompt for query parsing
  ├── repository_analyzer_system.erb         # System prompt for repo analysis
  └── repository_analyzer_build.erb          # User prompt with variables
```

**Creating New Prompts:**
```ruby
# Generate a new system prompt
Prompter.create("my_new_prompt", system: true)
# Creates: app/prompts/my_new_prompt_system.erb

# Generate a regular prompt
Prompter.create("my_prompt")
# Creates: app/prompts/my_prompt.erb
```

#### UserQueryParser Service (`app/services/user_query_parser.rb`)

Parses natural language queries into structured GitHub search parameters.

**Key Features:**
- **Multi-Query Support**: Can return 2-3 GitHub queries for comprehensive coverage
- **JSON Response**: Returns structured data with validation
- **Query Strategy**: Indicates "single" or "multi" query approach

```ruby
parser = UserQueryParser.new
result = parser.parse("I need a Rails background job library")

result[:github_queries]    # ["background job rails stars:>100", "sidekiq rails stars:>100"]
result[:query_strategy]    # "multi"
result[:tech_stack]        # "Rails, Ruby"
result[:problem_domain]    # "Background Job Processing"
result[:constraints]       # ["production ready", "retry logic"]
result[:valid]             # true
```

#### RepositoryAnalyzer Service (`app/services/repository_analyzer.rb`)

Analyzes and categorizes repositories using AI (formerly `RepositoryCategorizationService`).

**Methods:**
- `analyze_repository(repository)` - Tier 1 analysis using metadata + description
- `deep_dive_analysis(repository)` - Tier 2 analysis using README + issues (not yet implemented)

```ruby
analyzer = RepositoryAnalyzer.new
result = analyzer.analyze_repository(repo)

result[:categories]      # [{ category_id: 1, confidence: 0.95, reasoning: "..." }]
result[:summary]         # "Modern background job processor..."
result[:use_cases]       # ["Email sending", "Report generation"]
result[:input_tokens]    # 150
result[:output_tokens]   # 300
```

#### Github Service (`app/services/github.rb`)

Wrapper for GitHub API using Octokit gem.

```ruby
# Search repositories
results = Github.search("background job rails stars:>100", per_page: 30)

# Search trending repos
trending = Github.search_trending(days_ago: 7, language: "ruby", min_stars: 10)

# Instance methods also available
gh = Github.new
results = gh.search("query")
authenticated = gh.authenticated?
```

### Database Schema

**Core Tables:**
- **repositories**: GitHub repo data, cached README content, metadata
- **analyses**: Versioned AI-generated insights (Tier 1/Tier 2) with token/cost tracking
- **categories**: Categorization taxonomy (Problem Domain, Architecture Pattern, Maturity Level)
- **comparisons**: User queries with AI-generated repo comparisons (Tier 3)

**Join Tables:**
- **repository_categories**: Many-to-many with confidence scores, assignment method (ai/manual/github_topics)
- **comparison_repositories**: Links comparisons to repos with rank and score
- **comparison_categories**: Links comparisons to inferred categories

**Processing:**
- **queued_analyses**: Queue for batch Tier 1/Tier 2 analysis (priority, retry logic, scheduling)
- **ai_costs**: Daily rollup of AI API spending by model (auto-updated by OpenAi service)

### Cost Optimization Strategy

The app implements several strategies to keep AI API costs under $10/month:

1. **Automatic Cost Tracking**: `OpenAi` service automatically tracks all API calls to `ai_costs` table with daily rollup
2. **Model Whitelisting**: Only allow pre-approved models with known pricing to prevent cost surprises
3. **Selective Processing**: Only analyze repos that pass metadata filters (stars > 100, active within 30 days, relevant language)
4. **Tiered AI Models**: Use cheap models (gpt-4o-mini ~$0.001/repo) for categorization, expensive models only for deep dives
5. **Aggressive Caching**: Track `readme_sha` to detect changes; don't re-analyze unless content changed or 7+ days passed
6. **Batch Processing**: Queue repos during the day, process in nightly batches (limit 50/day)
7. **Multi-Query Strategy**: Use 2-3 GitHub queries to get comprehensive results, reducing need for expensive AI filtering

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

Jobs should use services that automatically track costs:

```ruby
class AnalyzeRepositoryJob < ApplicationJob
  queue_as :default

  def perform(repository_id)
    repo = Repository.find(repository_id)
    return unless repo.needs_analysis?

    # Use RepositoryAnalyzer service which uses OpenAi internally
    analyzer = RepositoryAnalyzer.new
    result = analyzer.analyze_repository(repo)

    # OpenAi service already tracked costs to ai_costs table
    # Just store the analysis results
    repo.analyses.create!(
      analysis_type: "tier1_categorization",
      summary: result[:summary],
      use_cases: result[:use_cases],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      model_used: "gpt-4o-mini",
      is_current: true
    )

    # Create category associations
    result[:categories].each do |cat|
      repo.repository_categories.create!(
        category_id: cat[:category_id],
        confidence_score: cat[:confidence],
        assigned_by: "ai"
      )
    end
  end
end
```

**Important Rules:**
1. ALWAYS use `OpenAi` service, NEVER call `OpenAI::Client` directly
2. Cost tracking is automatic - no need to manually calculate or save costs
3. The `OpenAi#chat` method returns standard OpenAI response object
4. Use `track_as:` parameter to label what the API call is for (helps debugging)

## Rails 8 Specific Features

- **Solid Queue**: Database-backed job processing (no Redis required). Job queues configured in `config/queue.yml`
- **Solid Cache**: Database-backed caching configured in `config/cache.yml`
- **Solid Cable**: Database-backed Action Cable for WebSocket connections
- **Thruster**: HTTP asset caching/compression (runs in production via Dockerfile)
- **Kamal**: Zero-downtime deployments with Docker containers (config in `config/deploy.yml`)

## Configuration Files & Directories

**Configuration:**
- `config/deploy.yml`: Kamal deployment configuration (servers, registry, environment variables)
- `config/recurring.yml`: Solid Queue recurring task definitions for scheduled jobs
- `config/queue.yml`: Solid Queue configuration

**AI Prompts:**
- `app/prompts/`: ERB templates for AI prompts (rendered by Prompter service)
- `app/prompts/README.md`: Documentation for prompt templates

**Services:**
- `app/services/`: All service classes following "Doer" naming pattern
  - `open_ai.rb`: OpenAI API wrapper with automatic cost tracking
  - `prompter.rb`: AI prompt template renderer
  - `user_query_parser.rb`: Natural language query parser
  - `repository_analyzer.rb`: Repository AI analysis
  - `github.rb`: GitHub API wrapper

**Testing/Analysis:**
- `lib/tasks/analyze.rake`: Rake tasks for testing AI analysis pipeline
  - `analyze:compare[query]`: Test full comparison pipeline
  - `analyze:validate_queries`: Run test suite with sample queries
  - `analyze:repo[full_name]`: Test Tier 1 analysis on single repo

**Documentation:**
- `README.md`: Project overview and getting started guide
- `TODO.md`: Current development status and next steps (root level)
- `CLAUDE.md`: This file - coding standards and architecture guide (root level)
- `docs/OVERVIEW.md`: Detailed project concept, database schema, and cost optimization strategies
- `docs/PLAN.md`: Phased build order from foundation to deployment
- `docs/SCHEMA.md`: Database schema documentation
- `docs/GITHUB_SEARCH_RESEARCH.md`: GitHub API search research and golden queries
- `docs/SECURITY_REVIEW.md`: Security audit summary and compliance documentation
