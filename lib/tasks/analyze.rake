namespace :analyze do
  desc "Test full comparison pipeline: parse query → multi-search → merge/dedupe → display results"
  desc "Usage: QUERY='your query here' bin/rails analyze:compare"
  task compare: :environment do
    # Use environment variable for easy natural language input (no escaping needed)
    query = ENV["QUERY"]

    unless query.present?
      puts "\n" + "=" * 80
      puts "🔬 COMPARISON PIPELINE TEST"
      puts "=" * 80
      puts "\n❌ No query provided!"
      puts "\n📖 Usage:"
      puts "  QUERY='your query here' bin/rails analyze:compare"
      puts "\n💡 Examples:"
      puts "  QUERY='I need a Rails background job library' bin/rails analyze:compare"
      puts "  QUERY='python orm with good migration support' bin/rails analyze:compare"
      puts "  QUERY='modern javascript testing framework' bin/rails analyze:compare"
      puts "\n" + "=" * 80
      puts ""
      exit
    end

    puts "\n" + "=" * 80
    puts "🔬 COMPARISON PIPELINE TEST"
    puts "=" * 80
    puts "User Query: #{query}"
    puts "=" * 80

    # Step 1: Parse the query
    parser = UserQueryParser.new
    result = parser.parse(query)

    unless result[:valid]
      puts "\n❌ Invalid Query"
      puts "Message: #{result[:validation_message]}"
      puts ""
      exit
    end

    puts "\n📋 PARSED DATA:"
    puts "  Tech Stack:     #{result[:tech_stack]}"
    puts "  Problem:        #{result[:problem_domain]}"
    puts "  Constraints:    #{result[:constraints].join(', ')}"
    puts "  Strategy:       #{result[:query_strategy]}"
    puts "\n🔍 GITHUB QUERIES (#{result[:github_queries].size}):"
    result[:github_queries].each_with_index do |q, i|
      puts "  #{i + 1}. #{q}"
    end

    # Step 2: Execute all GitHub searches
    puts "\n📡 EXECUTING GITHUB SEARCHES..."
    all_repos = []
    seen_full_names = Set.new

    result[:github_queries].each_with_index do |search_query, idx|
      begin
        puts "  Query #{idx + 1}: Searching..."
        gh_results = Github.search(search_query, per_page: 10)

        # Dedupe: only add repos we haven't seen yet
        new_repos = gh_results.items.reject { |repo| seen_full_names.include?(repo.full_name) }
        new_repos.each do |repo|
          all_repos << { repo: repo, found_by_query: idx + 1, query: search_query }
          seen_full_names.add(repo.full_name)
        end

        puts "    Found: #{gh_results.total_count} total | Added: #{new_repos.size} new (#{all_repos.size} total so far)"
      rescue => e
        puts "    ❌ Error: #{e.message}"
      end
    end

    # Step 3: Display merged results
    puts "\n" + "=" * 80
    puts "📊 MERGED RESULTS: #{all_repos.size} unique repositories"
    puts "=" * 80

    if all_repos.empty?
      puts "\n❌ No results found"
    else
      all_repos.first(10).each_with_index do |item, i|
        repo = item[:repo]
        puts "\n#{i + 1}. #{repo.full_name}"
        puts "   ⭐ #{repo.stargazers_count} | 🍴 #{repo.forks_count} | 🔧 #{repo.language || 'N/A'}"
        puts "   📝 #{repo.description&.slice(0, 100)}..." if repo.description
        puts "   🔍 Found by query ##{item[:found_by_query]}: #{item[:query]}"
      end

      puts "\n💭 EVALUATION QUESTIONS:"
      puts "  1. Are these the right repos for: '#{query}'?"
      puts "  2. Do you see the expected libraries in the top 5?"
      puts "  3. Any irrelevant results that should be filtered?"
      puts "  4. If multi-query: Did we catch repos that would've been missed by a single query?"
    end

    puts "\n" + "=" * 80
    puts "✅ Pipeline test complete"
    puts "=" * 80
    puts ""
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
