namespace :analyze do
  desc "Test repository fetcher: parse → fetch → analyze top 5 → prepare data"
  desc "Usage: QUERY='your query here' bin/rails analyze:fetch"
  task fetch: :environment do
    query = ENV["QUERY"]

    unless query.present?
      puts "\n" + "=" * 80
      puts "🔍 FETCH & PREPARE PIPELINE TEST"
      puts "=" * 80
      puts "\n❌ No query provided!"
      puts "\n📖 Usage:"
      puts "  QUERY='your query here' bin/rails analyze:fetch"
      puts "\n💡 Examples:"
      puts "  QUERY='Rails background job library' bin/rails analyze:fetch"
      puts "  QUERY='python orm for PostgreSQL' bin/rails analyze:fetch"
      puts "  QUERY='docker alternative' bin/rails analyze:fetch"
      puts "\n" + "=" * 80
      puts ""
      exit
    end

    puts "\n" + "=" * 80
    puts "🔍 FETCH & PREPARE PIPELINE TEST"
    puts "=" * 80
    puts "User Query: #{query}"
    puts "=" * 80

    # Step 1: Parse the query
    puts "\n📋 Step 1: Parsing query..."
    parser = UserQueryParser.new
    parsed = parser.parse(query)

    unless parsed[:valid]
      puts "\n❌ Invalid Query"
      puts "Message: #{parsed[:validation_message]}"
      puts ""
      exit
    end

    puts "  Tech Stack:     #{parsed[:tech_stack] || 'Language-agnostic'}"
    puts "  Problem:        #{parsed[:problem_domain]}"
    puts "  Constraints:    #{parsed[:constraints].join(', ')}"
    puts "  Strategy:       #{parsed[:query_strategy]}"
    puts "  GitHub Queries: #{parsed[:github_queries].size}"
    parsed[:github_queries].each_with_index do |q, i|
      puts "    #{i + 1}. #{q}"
    end

    # Step 2: Fetch and prepare repositories
    puts "\n📡 Step 2: Fetching and preparing repositories..."
    fetcher = RepositoryFetcher.new
    result = fetcher.fetch_and_prepare(
      github_queries: parsed[:github_queries],
      limit: 10
    )

    puts "  Total found: #{result[:total_found]}"
    puts "  Queries executed: #{result[:queries_executed]}"
    puts "  Top repos (analyzed): #{result[:top_repositories].size}"
    puts "  Other repos: #{result[:other_repositories].size}"

    # Display results
    puts "\n" + "=" * 80
    puts "📊 RESULTS"
    puts "=" * 80

    puts "\n🏆 TOP 5 (Analyzed & Ready for Comparison):"
    result[:top_repositories].each_with_index do |item, i|
      repo = item[:repository]
      signals = item[:quality_signals]

      puts "\n#{i + 1}. #{repo.full_name}"
      puts "   ⭐ #{signals[:stars]} stars | 🍴 #{signals[:forks]} forks | 🔧 #{signals[:language] || 'N/A'}"
      puts "   📅 Last updated: #{signals[:last_updated]&.strftime('%Y-%m-%d') || 'Unknown'}"
      puts "   📈 Growth: #{signals[:stars_per_day]} stars/day (#{signals[:age_days]} days old)"
      puts "   #{signals[:has_analysis] ? '✅ Analyzed' : '⚠️  Not analyzed'}"
      puts "   #{signals[:is_archived] ? '📦 ARCHIVED' : ''}"
    end

    if result[:other_repositories].any?
      puts "\n💡 OTHER OPTIONS (Not yet analyzed):"
      result[:other_repositories].each_with_index do |item, i|
        repo = item[:repository]
        signals = item[:quality_signals]
        puts "  #{i + 6}. #{repo.full_name} - ⭐ #{signals[:stars]} | #{signals[:language] || 'N/A'}"
      end
    end

    puts "\n" + "=" * 80
    puts "✅ Fetch & prepare test complete"
    puts "=" * 80
    puts ""
  end

  desc "Full comparison pipeline: parse → fetch → analyze → compare (creates Comparison record)"
  desc "Usage: QUERY='your query here' bin/rails analyze:compare"
  task compare: :environment do
    query = ENV["QUERY"]

    unless query.present?
      puts "\n" + "=" * 80
      puts "🏆 FULL COMPARISON PIPELINE TEST"
      puts "=" * 80
      puts "\n❌ No query provided!"
      puts "\n📖 Usage:"
      puts "  QUERY='your query here' bin/rails analyze:compare"
      puts "\n💡 Examples:"
      puts "  QUERY='Rails background job library with retry logic' bin/rails analyze:compare"
      puts "  QUERY='Python ORM for PostgreSQL' bin/rails analyze:compare"
      puts "  QUERY='React state management for large apps' bin/rails analyze:compare"
      puts "\n" + "=" * 80
      puts ""
      exit
    end

    puts "\n" + "=" * 80
    puts "🏆 FULL COMPARISON PIPELINE TEST"
    puts "=" * 80
    puts "User Query: #{query}"
    puts "=" * 80

    # Run comparison pipeline via ComparisonCreator service
    puts "\n🔄 Running comparison pipeline (parse → fetch → analyze → compare)..."
    puts "   This will take ~10-15 seconds and cost ~$0.05"

    begin
      result = ComparisonCreator.call(query: query, force_refresh: true)
      comparison = result.record

      if result.newly_created
        puts "\n✅ Created new comparison"
      else
        puts "\n💾 Found cached result (#{(result.similarity * 100).round}% similarity)"
      end

      # Display results
      puts "\n" + "=" * 80
      puts "🏆 COMPARISON RESULTS"
      puts "=" * 80

      puts "\n✨ RECOMMENDATION: #{comparison.recommended_repo_full_name}"
      puts "#{comparison.recommendation_reasoning}"

      puts "\n📊 RANKING:"
      comparison.comparison_repositories.order(:rank).each do |cr|
        puts "\n#{cr.rank}. #{cr.repository.full_name} (Score: #{cr.score}/100)"
        puts "   👍 Pros:"
        cr.pros.each { |pro| puts "      • #{pro}" }
        if cr.cons.any?
          puts "   👎 Cons:"
          cr.cons.each { |con| puts "      • #{con}" }
        end
        puts "   💡 Fit: #{cr.fit_reasoning}"
      end

      puts "\n💰 Cost: $#{comparison.cost_usd.round(6)} (#{comparison.input_tokens} in / #{comparison.output_tokens} out)"
      puts "\n✅ Comparison saved! ID: #{comparison.id}"
      puts "🔗 View at: http://localhost:3000/comparisons/#{comparison.id}"

      puts "\n" + "=" * 80
      puts "✅ Full comparison pipeline complete"
      puts "=" * 80
      puts ""
    rescue ComparisonCreator::InvalidQueryError => e
      puts "\n❌ Invalid Query: #{e.message}"
      exit 1
    rescue ComparisonCreator::NoRepositoriesFoundError => e
      puts "\n❌ No repositories found"
      puts "   Try different keywords or be more specific"
      exit 1
    rescue => e
      puts "\n❌ Error: #{e.class} - #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    end
  end

  desc "Run comprehensive test suite with 30 diverse queries"
  task test_suite: :environment do
    test_queries = [
      # Rails / Ruby
      "I need a Rails background job library",
      "What's the best authentication solution for Rails? I need OAuth support and good documentation",
      "ruby gem for processing payments, needs stripe and paypal",
      "I'm building a Rails API and need really good serialization that's fast",
      "state machine for ruby",

      # Python
      "python orm with good migration support",
      "I need a Python web framework that's fast and async, not Django",
      "what should I use for data validation in Python? Working with APIs",
      "python library for scraping websites",
      "task queue for python with retry logic and monitoring",

      # JavaScript / TypeScript / Node.js
      "modern javascript testing framework",
      "I need a Node.js framework for building APIs, prefer TypeScript support",
      "what's good for state management in React apps nowadays?",
      "form validation library for react",
      "node.js orm that works with postgres and mysql",
      "Looking for a bundler for my frontend project, needs to be fast and support TypeScript",

      # Frontend / UI
      "css framework that's not bootstrap",
      "I need a component library for Vue 3",
      "datatable library for displaying large datasets in the browser",
      "charting library for dashboards, needs to look good and be interactive",

      # DevOps / Infrastructure
      "docker alternative",
      "I need something to deploy my Rails app easily without a ton of DevOps knowledge",
      "monitoring solution for production apps",
      "CI/CD tool for github that's free for small teams",

      # Database / Data
      "document database for nodejs apps",
      "fast cache for reducing database load",
      "full-text search engine",

      # Other Languages / Use Cases
      "go web framework",
      "command line argument parser for rust",
      "I want to build desktop apps with web technologies"
    ]

    parser = UserQueryParser.new
    results = []

    puts "\n" + "=" * 80
    puts "🧪 COMPREHENSIVE TEST SUITE - 30 QUERIES"
    puts "=" * 80
    puts "Running all queries and collecting statistics...\n"

    test_queries.each_with_index do |query, idx|
      print "#{idx + 1}/30: #{query[0..60]}#{'...' if query.length > 60} "

      begin
        # Parse query
        parsed = parser.parse(query)

        # Execute searches
        all_repos = []
        seen_full_names = Set.new

        parsed[:github_queries].each do |search_query|
          begin
            gh_results = Github.search(search_query, per_page: 10)
            new_repos = gh_results.items.reject { |repo| seen_full_names.include?(repo.full_name) }
            new_repos.each do |repo|
              all_repos << repo
              seen_full_names.add(repo.full_name)
            end
          rescue => e
            # Silently continue on API errors
          end
        end

        results << {
          query: query,
          valid: parsed[:valid],
          strategy: parsed[:query_strategy],
          num_queries: parsed[:github_queries].size,
          num_results: all_repos.size,
          top_repo: all_repos.first&.full_name,
          tech_stack: parsed[:tech_stack],
          problem_domain: parsed[:problem_domain],
          constraints: parsed[:constraints]
        }

        puts "✅ (#{parsed[:query_strategy]}, #{all_repos.size} results)"
      rescue => e
        results << {
          query: query,
          valid: false,
          error: e.message
        }
        puts "❌ ERROR: #{e.message}"
      end
    end

    # Analyze results
    puts "\n" + "=" * 80
    puts "📊 HOLISTIC ANALYSIS"
    puts "=" * 80

    valid_results = results.select { |r| r[:valid] }
    invalid_results = results.reject { |r| r[:valid] }

    single_strategy = valid_results.select { |r| r[:strategy] == "single" }
    multi_strategy = valid_results.select { |r| r[:strategy] == "multi" }

    zero_results = valid_results.select { |r| r[:num_results] == 0 }
    low_results = valid_results.select { |r| r[:num_results] > 0 && r[:num_results] < 5 }
    good_results = valid_results.select { |r| r[:num_results] >= 5 }

    puts "\n🎯 Overall Success Rate:"
    puts "  Valid queries: #{valid_results.size}/#{results.size} (#{(valid_results.size.to_f / results.size * 100).round(1)}%)"
    puts "  Invalid/Error: #{invalid_results.size}/#{results.size}"

    puts "\n🔍 Query Strategy Distribution:"
    puts "  Single-query: #{single_strategy.size}/#{valid_results.size} (#{(single_strategy.size.to_f / valid_results.size * 100).round(1)}%)"
    puts "  Multi-query:  #{multi_strategy.size}/#{valid_results.size} (#{(multi_strategy.size.to_f / valid_results.size * 100).round(1)}%)"

    puts "\n📈 Results Quality:"
    puts "  Zero results:     #{zero_results.size}/#{valid_results.size}"
    puts "  Low results (1-4): #{low_results.size}/#{valid_results.size}"
    puts "  Good results (5+): #{good_results.size}/#{valid_results.size}"

    if zero_results.any?
      puts "\n⚠️  Queries with ZERO results:"
      zero_results.each do |r|
        puts "  - #{r[:query]}"
        puts "    Strategy: #{r[:strategy]}, Queries: #{r[:num_queries]}"
      end
    end

    if invalid_results.any?
      puts "\n❌ Invalid/Error queries:"
      invalid_results.each do |r|
        puts "  - #{r[:query]}"
        puts "    Error: #{r[:error]}"
      end
    end

    puts "\n🏆 Multi-Query Examples (showing it's working):"
    multi_strategy.first(5).each do |r|
      puts "  - #{r[:query]}"
      puts "    Queries: #{r[:num_queries]}, Results: #{r[:num_results]}, Top: #{r[:top_repo]}"
    end

    puts "\n📋 Tech Stack Coverage:"
    tech_stacks = valid_results.map { |r| r[:tech_stack] }.compact.tally.sort_by { |k, v| -v }
    tech_stacks.first(10).each do |stack, count|
      puts "  #{stack}: #{count} queries"
    end

    puts "\n" + "=" * 80
    puts "✅ Test suite complete"
    puts "=" * 80
    puts ""
  end

  desc "Validate query parser with test suite of known queries"
  task validate_queries: :environment do
    test_cases = [
      {
        query: "I need a Rails background job library with retry logic",
        expected_repos: ["sidekiq/sidekiq", "bensheldon/good_job"],
        expected_strategy: "single"
      },
      {
        query: "Looking for a Python authentication library that supports OAuth",
        expected_repos: ["pennersr/django-allauth", "lepture/authlib"],
        expected_strategy: "single"
      },
      {
        query: "Need a React state management library for large applications",
        expected_repos: ["reduxjs/redux", "pmndrs/zustand", "mobxjs/mobx"],
        expected_strategy: "single"
      },
      {
        query: "I need a Python ORM for PostgreSQL",
        expected_repos: ["sqlalchemy/sqlalchemy", "encode/orm", "django/django"],
        expected_strategy: "multi"
      },
      {
        query: "Looking for a Node.js web framework",
        expected_repos: ["expressjs/express", "fastify/fastify", "koajs/koa"],
        expected_strategy: "multi"
      },
      {
        query: "I need a JavaScript testing framework",
        expected_repos: ["jestjs/jest", "mochajs/mocha", "vitest-dev/vitest"],
        expected_strategy: "multi"
      }
    ]

    parser = UserQueryParser.new
    total_tests = test_cases.size
    passed_tests = 0

    puts "\n" + "=" * 80
    puts "🧪 QUERY VALIDATION TEST SUITE"
    puts "=" * 80
    puts "Running #{total_tests} test cases...\n"

    test_cases.each_with_index do |test, idx|
      puts "\n" + "-" * 80
      puts "Test #{idx + 1}/#{total_tests}: #{test[:query]}"
      puts "-" * 80

      # Parse the query
      result = parser.parse(test[:query])

      # Check if valid
      unless result[:valid]
        puts "❌ FAIL - Query marked as invalid"
        puts "   Reason: #{result[:validation_message]}"
        next
      end

      # Check strategy
      strategy_match = result[:query_strategy] == test[:expected_strategy]
      puts "Strategy: #{result[:query_strategy]} #{strategy_match ? '✅' : '⚠️  (expected: ' + test[:expected_strategy] + ')'}"
      puts "Queries:  #{result[:github_queries].join(' | ')}"

      # Execute searches and check for expected repos
      all_repos = []
      seen_full_names = Set.new

      result[:github_queries].each do |search_query|
        begin
          gh_results = Github.search(search_query, per_page: 10)
          new_repos = gh_results.items.reject { |repo| seen_full_names.include?(repo.full_name) }
          new_repos.each do |repo|
            all_repos << repo
            seen_full_names.add(repo.full_name)
          end
        rescue => e
          puts "❌ GitHub search error: #{e.message}"
        end
      end

      # Check if expected repos are in results
      found_repos = all_repos.map(&:full_name)
      matched = test[:expected_repos] & found_repos

      puts "\nExpected repos: #{test[:expected_repos].join(', ')}"
      puts "Found #{matched.size}/#{test[:expected_repos].size}: #{matched.join(', ')}"

      if matched.size >= (test[:expected_repos].size * 0.5).ceil
        puts "✅ PASS - Found at least half of expected repos"
        passed_tests += 1
      else
        puts "❌ FAIL - Missing too many expected repos"
        puts "   Top 5 results: #{found_repos.first(5).join(', ')}"
      end
    end

    puts "\n" + "=" * 80
    puts "📊 RESULTS: #{passed_tests}/#{total_tests} tests passed"
    puts "=" * 80
    puts ""
  end

  desc "Analyze a single repository (Tier 1 categorization)"
  desc "Usage: REPO='owner/name' bin/rails analyze:repo"
  task repo: :environment do
    full_name = ENV["REPO"]

    unless full_name.present?
      puts "\n" + "=" * 80
      puts "🤖 REPOSITORY ANALYSIS"
      puts "=" * 80
      puts "\n❌ No repository provided!"
      puts "\n📖 Usage:"
      puts "  REPO='owner/name' bin/rails analyze:repo"
      puts "\n💡 Examples:"
      puts "  REPO='mperham/sidekiq' bin/rails analyze:repo"
      puts "  REPO='rails/rails' bin/rails analyze:repo"
      puts "  REPO='facebook/react' bin/rails analyze:repo"
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
        github = Github.new
        gh_repo = github.repository(full_name)
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

    # Run Tier 1 analysis
    puts "\n🤖 Running Tier 1 Analysis (gpt-4o-mini)..."

    analyzer = RepositoryAnalyzer.new
    result = analyzer.analyze_repository(repo)

    # Create analysis record
    analysis = repo.analyses.create!(
      analysis_type: "tier1_categorization",
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
end
