# RepoReconnoiter

An Open Source Intelligence Dashboard that analyzes GitHub trending repositories using AI to provide developers with context-aware recommendations.

**🚀 Live Demo**: [https://reporeconnoiter.com](https://reporeconnoiter.com)

## Features

- 🔍 **Multi-Query Search**: Intelligent query parsing with 2-3 GitHub searches for comprehensive results
- 🤖 **AI-Powered Analysis**: Three-tier analysis system (categorization, deep dive, comparison)
- 💰 **Cost Tracking**: Automatic API cost monitoring with $10/month budget management
- 📊 **Smart Categorization**: AI categorizes repos by problem domain, architecture pattern, and maturity
- ⚡ **Aggressive Caching**: Only re-analyzes when README changes or significant activity detected

## Tech Stack

- **Framework**: Rails 8.1 with Hotwire/Turbo + Stimulus
- **Database**: PostgreSQL
- **Background Jobs**: Solid Queue (database-backed, no Redis)
- **AI Provider**: OpenAI (gpt-4o-mini for categorization, gpt-4o for deep analysis)
- **Styling**: Tailwind CSS
- **Ruby**: 3.4.7

## Prerequisites

Before you begin, ensure you have the following installed:

- Ruby 3.4.7 (use rbenv or rvm)
- PostgreSQL 14+ (running and accessible)
- Node.js 18+ (for JavaScript dependencies)
- Yarn or npm

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/repo-reconnoiter.git
cd repo-reconnoiter
```

### 2. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install JavaScript dependencies
yarn install
# or
npm install
```

### 3. Configure API Keys

You'll need API keys for:

- **OpenAI**: For AI-powered repository analysis
- **GitHub**: For searching and fetching repository data

#### Get Your API Keys

**OpenAI API Key:**

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new secret key
5. Copy the key (you won't be able to see it again)

**GitHub Personal Access Token:**

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "RepoReconnoiter Development")
4. Select scopes: `public_repo`, `read:user`
5. Generate token and copy it

#### Store Keys Securely (Rails Credentials)

Rails 8 uses encrypted credentials to store secrets. Never commit API keys to version control!

**Edit encrypted credentials:**

```bash
# This opens your editor with decrypted credentials
EDITOR="code --wait" bin/rails credentials:edit
# or use vim/nano/etc:
# EDITOR="vim" bin/rails credentials:edit
```

**Add your API keys:**

```yaml
openai:
  api_key: sk-your-openai-api-key-here

github:
  access_token: ghp_your-github-token-here

# Optional: For production deployment
secret_key_base: <%= SecureRandom.hex(64) %>
```

**Save and close the editor** - Rails will automatically encrypt the file.

**Important Files:**

- `config/credentials.yml.enc` - Encrypted credentials (safe to commit)
- `config/master.key` - Decryption key (DO NOT COMMIT - add to .gitignore)

The `master.key` is automatically in `.gitignore`. Keep it safe - you'll need it to decrypt credentials.

### 4. Database Setup

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Seed initial data (creates category taxonomy)
bin/rails db:seed
```

### 5. Verify Configuration

Test that your API keys are configured correctly:

```bash
# Open Rails console
bin/rails console

# Test OpenAI configuration
> ai = OpenAi.new
> ai.chat(messages: [{role: "user", content: "Hi"}], model: "gpt-4o-mini")
# Should return a response object (not an error)

# Test GitHub configuration
> gh = Github.new
> gh.authenticated?
# Should return true

# Exit console
> exit
```

## Running the Application

### Development Mode

Start all development services (Puma web server, Solid Queue worker, Tailwind CSS watcher):

```bash
bin/dev
```

This starts:

- **Web server**: <http://localhost:3000>
- **Background jobs**: Solid Queue worker
- **Tailwind CSS**: File watcher for CSS changes

### Individual Services

If you need to run services separately:

```bash
# Web server only
bin/rails server

# Background jobs only
bin/rails solid_queue:start

# Tailwind CSS watcher only
bin/rails tailwindcss:watch
```

## Testing the AI Pipeline

Test the AI analysis pipeline with rake tasks:

```bash
# Test full comparison pipeline (parse → search → merge)
QUERY="I need a Rails background job library" bin/rails analyze:compare

# More examples (supports commas, quotes, any natural language)
QUERY="python orm with good migration support" bin/rails analyze:compare
QUERY="ruby gem for payments, needs stripe and paypal" bin/rails analyze:compare
QUERY="what's good for state management in React?" bin/rails analyze:compare

# Run test suite with sample queries
bin/rails analyze:validate_queries

# Test Tier 1 analysis on a single repo
REPO="mperham/sidekiq" bin/rails analyze:basic
```

## Running Tests

```bash
# Run all tests
bin/rails test

# Run system tests
bin/rails test:system

# Run specific test file
bin/rails test test/models/repository_test.rb
```

## Code Quality

```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -a

# Security vulnerability scanner
bin/brakeman

# Check for vulnerable gems
bin/bundler-audit
```

## Monitoring AI Costs

Check your AI API spending:

```bash
bin/rails console

# Today's costs
> AiCost.total_cost_today

# This week's costs
> AiCost.total_cost_this_week

# This month's costs
> AiCost.total_cost_this_month

# Budget status (default: $10/month)
> AiCost.budget_status
# => { budget: 10.0, spent: 2.34, remaining: 7.66, percentage: 23.4, status: :healthy }

# Projected monthly cost based on current usage
> AiCost.projected_monthly_cost
```

## Project Structure

```
repo-reconnoiter/
├── app/
│   ├── models/           # ActiveRecord models
│   ├── services/         # Service objects (Doer pattern)
│   │   ├── open_ai.rb           # OpenAI API wrapper with cost tracking
│   │   ├── prompter.rb          # AI prompt template renderer
│   │   ├── user_query_parser.rb # Natural language query parser
│   │   ├── repository_analyzer.rb # AI repository analysis
│   │   └── github.rb            # GitHub API wrapper
│   ├── prompts/          # AI prompt templates (ERB)
│   ├── controllers/
│   ├── views/
│   └── jobs/             # Background jobs (Solid Queue)
├── lib/tasks/            # Rake tasks
│   └── analyze.rake      # AI pipeline testing tasks
├── config/
│   ├── credentials.yml.enc  # Encrypted API keys (safe to commit)
│   ├── master.key           # Decryption key (DO NOT COMMIT)
│   └── recurring.yml        # Scheduled background jobs
├── db/
│   ├── migrate/          # Database migrations
│   └── seeds.rb          # Initial data (categories)
├── CLAUDE.md             # Coding standards and architecture
├── OVERVIEW.md           # Project concept and strategy
└── TODO.md               # Development roadmap
```

## Troubleshooting

### "Master key is missing" Error

If you see `ActiveSupport::MessageEncryptor::InvalidMessage`:

```bash
# The master.key file is missing or incorrect
# Generate a new one:
EDITOR="code --wait" bin/rails credentials:edit
# This creates a new master.key if missing
```

### OpenAI API Errors

```bash
# Verify your API key is set correctly
bin/rails console
> Rails.application.credentials.openai&.api_key
# Should show your key (first few characters)

# Test with a simple call
> ai = OpenAi.new
> ai.chat(messages: [{role: "user", content: "test"}], model: "gpt-4o-mini")
```

### GitHub API Rate Limiting

```bash
# Check if you're authenticated (higher rate limits)
bin/rails console
> gh = Github.new
> gh.authenticated?
# Should return true

# Without authentication: 60 requests/hour
# With authentication: 5,000 requests/hour
```

### Database Connection Issues

```bash
# Verify PostgreSQL is running
pg_isready

# Check database.yml configuration
cat config/database.yml

# Recreate database if needed
bin/rails db:drop db:create db:migrate db:seed
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the coding standards in `CLAUDE.md`
4. Write tests for new features
5. Ensure all tests pass (`bin/rails test`)
6. Run RuboCop (`bin/rubocop`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

- 📖 Read `CLAUDE.md` for coding standards and architecture
- 📋 Check `OVERVIEW.md` for project strategy and database schema
- 🗺️ See `TODO.md` for development roadmap
- 🐛 Report issues on GitHub Issues

## Acknowledgments

- Built with Rails 8.1 and the Solid Stack
- Powered by OpenAI's GPT models
- GitHub API for repository data
