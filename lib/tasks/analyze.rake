namespace :analyze do
  desc "Run basic analysis on a repository (Tier 1 categorization)"
  desc "Usage: REPO='owner/name' bin/rails analyze:basic"
  task basic: :environment do
    full_name = ENV["REPO"]

    unless full_name.present?
      puts "\n" + "=" * 80
      puts "🤖 BASIC REPOSITORY ANALYSIS"
      puts "=" * 80
      puts "\n❌ No repository provided!"
      puts "\n📖 Usage:"
      puts "  REPO='owner/name' bin/rails analyze:basic"
      puts "\n💡 Examples:"
      puts "  REPO='mperham/sidekiq' bin/rails analyze:basic"
      puts "  REPO='rails/rails' bin/rails analyze:basic"
      puts "  REPO='facebook/react' bin/rails analyze:basic"
      puts "\n" + "=" * 80
      puts ""
      exit
    end

    puts "\n" + "=" * 80
    puts "🤖 REPOSITORY ANALYSIS"
    puts "=" * 80
    puts "Repository: #{full_name}"
    puts "=" * 80

    # Check if repo exists in DB
    repo = Repository.find_by(full_name: full_name)

    # If not in DB, fetch from GitHub
    unless repo
      puts "\n📡 Fetching from GitHub API..."
      begin
        client = Octokit::Client.new(
          access_token: Rails.application.credentials.github&.personal_access_token
        )
        gh_repo = client.repository(full_name)
        repo = Repository.from_github_api(gh_repo.to_attrs)
        repo.save!
        puts "✅ Repository saved to database"
      rescue => e
        puts "❌ Error fetching repository: #{e.message}"
        exit
      end
    else
      puts "\n✅ Repository found in database"
    end

    # Run basic analysis
    puts "\n🤖 Running Analysis (gpt-4o-mini)..."

    analyzer = RepositoryAnalyzer.new
    result = analyzer.analyze(repo)

    # Create analysis record (defaults to Analysis base class)
    analysis = repo.analyses.create!(
      model_used: "gpt-4o-mini",
      summary: result[:summary],
      use_cases: result[:use_cases],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      is_current: true
    )

    puts "\n" + "=" * 80
    puts "📋 ANALYSIS RESULTS"
    puts "=" * 80
    puts "\n📝 Summary:\n#{result[:summary]}\n"
    puts "\n💡 Use Cases:\n#{result[:use_cases]}\n"
    puts "\n🏷️  Categories (#{result[:categories].size}):"
    result[:categories].each do |cat|
      puts "  - #{cat['name']} (#{cat['category_type']}) - #{(cat['confidence'] * 100).round}% confidence"
    end

    puts "\n💰 Cost:"
    puts "  Tokens: #{result[:input_tokens]} in / #{result[:output_tokens]} out"
    puts "  Cost:   $#{analysis.cost_usd.round(6)}"

    puts "\n" + "=" * 80
    puts ""
  end

  desc "Run deep analysis on a repository (admin only, expensive ~$0.05-0.10)"
  desc "Usage: REPO='owner/name' bin/rails analyze:deep"
  task deep: :environment do
    full_name = ENV["REPO"]

    unless full_name.present?
      puts "\n" + "=" * 80
      puts "🔬 DEEP REPOSITORY ANALYSIS"
      puts "=" * 80
      puts "\n❌ No repository provided!"
      puts "\n📖 Usage:"
      puts "  REPO='owner/name' bin/rails analyze:deep"
      puts "\n💡 Examples:"
      puts "  REPO='mperham/sidekiq' bin/rails analyze:deep"
      puts "  REPO='rails/rails' bin/rails analyze:deep"
      puts "  REPO='facebook/react' bin/rails analyze:deep"
      puts "\n⚠️  WARNING: This uses gpt-4o and costs ~$0.05-0.10 per repo!"
      puts "=" * 80
      puts ""
      exit
    end

    puts "\n" + "=" * 80
    puts "🔬 DEEP REPOSITORY ANALYSIS"
    puts "=" * 80
    puts "Repository: #{full_name}"
    puts "⚠️  Using gpt-4o (expensive model)"
    puts "=" * 80

    # Check budget
    unless AnalysisDeep.can_create_today?
      remaining = AnalysisDeep.remaining_budget_today
      puts "\n❌ Daily budget exceeded!"
      puts "Remaining budget: $#{remaining.round(4)}"
      puts "Daily budget cap: $#{AnalysisDeep::DAILY_BUDGET}"
      puts "\nTry again tomorrow or adjust DAILY_BUDGET in AnalysisDeep model."
      exit
    end

    # Check if repo exists in DB
    repo = Repository.find_by(full_name: full_name)

    # If not in DB, fetch from GitHub
    unless repo
      puts "\n📡 Fetching from GitHub API..."
      begin
        client = Octokit::Client.new(
          access_token: Rails.application.credentials.github&.personal_access_token
        )
        gh_repo = client.repository(full_name)
        repo = Repository.from_github_api(gh_repo.to_attrs)
        repo.save!
        puts "✅ Repository saved to database"
      rescue => e
        puts "❌ Error fetching repository: #{e.message}"
        exit
      end
    else
      puts "\n✅ Repository found in database"
    end

    # Run deep analysis
    puts "\n🔬 Running Deep Analysis (gpt-4o)..."
    puts "This will take 30-60 seconds and cost ~$0.05-0.10"
    puts ""

    analyzer = RepositoryDeepAnalyzer.new
    result = analyzer.analyze(repo)

    # Create analysis record
    analysis = repo.analyses.create!(
      type: "AnalysisDeep",
      model_used: "gpt-4o",
      readme_analysis: result[:readme_analysis],
      issues_analysis: result[:issues_analysis],
      maintenance_analysis: result[:maintenance_analysis],
      adoption_analysis: result[:adoption_analysis],
      security_analysis: result[:security_analysis],
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      is_current: true
    )

    puts "\n" + "=" * 80
    puts "📋 DEEP ANALYSIS RESULTS"
    puts "=" * 80

    puts "\n📖 README ANALYSIS:"
    puts "-" * 80
    puts result[:readme_analysis]

    puts "\n\n🐛 ISSUES ANALYSIS:"
    puts "-" * 80
    puts result[:issues_analysis]

    puts "\n\n🔧 MAINTENANCE ANALYSIS:"
    puts "-" * 80
    puts result[:maintenance_analysis]

    puts "\n\n🚀 ADOPTION ANALYSIS:"
    puts "-" * 80
    puts result[:adoption_analysis]

    puts "\n\n🔒 SECURITY ANALYSIS:"
    puts "-" * 80
    puts result[:security_analysis]

    puts "\n\n💰 COST DETAILS:"
    puts "-" * 80
    puts "  Input tokens:  #{result[:input_tokens].to_s.rjust(8)}"
    puts "  Output tokens: #{result[:output_tokens].to_s.rjust(8)}"
    puts "  Total cost:    $#{analysis.cost_usd.round(6)}"
    puts "  Remaining budget today: $#{AnalysisDeep.remaining_budget_today.round(4)}"

    puts "\n" + "=" * 80
    puts "✅ Deep analysis complete and saved!"
    puts "=" * 80
    puts ""
  end
end
