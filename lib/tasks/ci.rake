# CI tasks that mirror GitHub Actions workflow
# Run locally before pushing to catch failures early
namespace :ci do
  desc "Run all CI checks (security, lint, tests)"
  task all: %w[ci:security ci:lint ci:test]

  desc "Run security scans (Brakeman, Bundler Audit, Importmap)"
  task :security do
    puts "\n🔒 Running security scans..."
    sh "bin/brakeman --no-pager"
    sh "bin/bundler-audit"
    sh "bin/importmap audit"
  end

  desc "Run RuboCop linter"
  task :lint do
    puts "\n✨ Running linter..."
    sh "bin/rubocop"
  end

  desc "Run all tests (unit + system)"
  task :test do
    puts "\n🧪 Running tests..."
    sh "bin/rails db:test:prepare"
    sh "bin/rails test"
    sh "bin/rails test:system"
  end
end
