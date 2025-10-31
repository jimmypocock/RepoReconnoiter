namespace :analyze do
  desc "Test full comparison pipeline: parse query → multi-search → merge/dedupe → display results"
  task :compare, [ :query ] => :environment do |t, args|
    query = args[:query] || "I need a Rails background job library with retry logic"

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
  task :repo, [ :full_name ] => :environment do |t, args|
    full_name = args[:full_name] || "sidekiq/sidekiq"

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
