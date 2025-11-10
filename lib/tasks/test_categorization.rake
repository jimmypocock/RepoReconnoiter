namespace :test do
  desc "Test comparison category assignment with predefined queries"
  task categorization: :environment do
    test_scenarios = [
      {
        query: "Java authentication library with JWT support",
        min_categories: 3,
        must_include: [ "java" ]
      },
      {
        query: "TypeScript GraphQL server framework",
        min_categories: 3,
        must_include: [ "typescript" ]
      },
      {
        query: "Elixir real-time Phoenix application framework",
        min_categories: 2,
        must_include: [ "elixir" ]
      }
    ]

    results = []

    test_scenarios.each_with_index do |scenario, index|
      puts "\n" + "=" * 80
      puts "Test #{index + 1}/#{test_scenarios.size}: #{scenario[:query]}"
      puts "=" * 80

      result = run_test(scenario)
      results << result

      print_result(result)
    end

    print_summary(results)
  end

  def run_test(scenario)
    comparison = create_comparison(scenario[:query])

    {
      query: scenario[:query],
      comparison_id: comparison.id,
      categories_by_type: group_categories_with_sources(comparison),
      repos_used: comparison.repositories.order("comparison_repositories.rank").limit(5).pluck(:full_name),
      total_repos: comparison.repos_compared_count,
      checks: run_checks(comparison, scenario)
    }
  rescue StandardError => e
    {
      query: scenario[:query],
      error: e.message,
      checks: { passed: false }
    }
  end

  def create_comparison(query)
    puts "→ Creating comparison..."

    user = User.first
    unless user
      raise "No users found. Create a user first or run db:seed"
    end

    parser = UserQueryParser.new
    parsed_query = parser.parse(query)

    unless parsed_query[:valid]
      raise "Query parsing failed: #{parsed_query[:errors]}"
    end

    fetcher = RepositoryFetcher.new
    result = fetcher.fetch_and_prepare(
      github_queries: parsed_query[:github_queries],
      limit: 15
    )

    repositories = result[:top_repositories]

    if repositories.empty?
      raise "No repositories found for query"
    end

    comparer = RepositoryComparer.new
    comparison = comparer.compare_repositories(
      user_query: query,
      parsed_query: parsed_query,
      repositories: repositories,
      user: user
    )

    puts "✓ Comparison created (ID: #{comparison.id})"
    comparison
  end

  def group_categories_with_sources(comparison)
    grouped = {}

    comparison.comparison_categories.includes(:category).each do |cc|
      type = cc.category.category_type
      grouped[type] ||= []
      grouped[type] << {
        name: cc.category.name,
        slug: cc.category.slug,
        assigned_by: cc.assigned_by,
        confidence_score: cc.confidence_score
      }
    end

    grouped.transform_values { |cats| cats.sort_by { |c| [-c[:confidence_score].to_f, c[:name]] } }
  end

  def run_checks(comparison, scenario)
    actual_slugs = comparison.categories.pluck(:slug)

    checks = {
      min_categories: {
        passed: actual_slugs.size >= scenario[:min_categories],
        expected: scenario[:min_categories],
        actual: actual_slugs.size
      },
      must_include: {
        passed: scenario[:must_include].all? { |slug| actual_slugs.include?(slug) },
        expected: scenario[:must_include],
        missing: scenario[:must_include] - actual_slugs
      }
    }

    checks[:passed] = checks.values.all? { |check| check[:passed] }
    checks
  end

  def print_result(result)
    if result[:error]
      puts "\n❌ ERROR: #{result[:error]}"
      return
    end

    puts "\n📊 Results:"
    puts "   Comparison ID: #{result[:comparison_id]}"
    puts "   Total repos compared: #{result[:total_repos]}"

    puts "\n📦 Top 5 Repositories:"
    result[:repos_used].each_with_index do |repo, index|
      puts "   #{index + 1}. #{repo}"
    end

    puts "\n🏷️  Categories Assigned:"
    if result[:categories_by_type].empty?
      puts "   (none)"
    else
      result[:categories_by_type].each do |type, categories|
        puts "\n   #{type.upcase} (#{categories.size}):"
        categories.each do |cat|
          confidence = cat[:confidence_score] ? sprintf("%.2f", cat[:confidence_score]) : "N/A"
          puts "     • #{cat[:name]} (#{cat[:slug]}) [#{cat[:assigned_by]}] (#{confidence})"
        end
      end
    end

    puts "\n✅ Validation Checks:"
    checks = result[:checks]

    min_check = checks[:min_categories]
    status = min_check[:passed] ? "✓" : "✗"
    puts "   #{status} Min categories: #{min_check[:actual]} >= #{min_check[:expected]}"

    must_check = checks[:must_include]
    status = must_check[:passed] ? "✓" : "✗"
    if must_check[:passed]
      puts "   #{status} Must include: #{must_check[:expected].join(', ')}"
    else
      puts "   #{status} Must include: #{must_check[:expected].join(', ')}"
      puts "      Missing: #{must_check[:missing].join(', ')}"
    end

    overall = checks[:passed] ? "✓ PASSED" : "✗ FAILED"
    puts "\n   #{overall}"
  end

  def print_summary(results)
    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80

    passed = results.count { |r| r.dig(:checks, :passed) }
    total = results.size

    puts "Tests passed: #{passed}/#{total}"

    if passed == total
      puts "\n✅ All tests passed!"
    else
      puts "\n⚠️  Some tests failed. Review results above."
    end

    puts "\n💡 Next steps:"
    puts "   1. Review category assignments above"
    puts "   2. Verify they match your expectations"
    puts "   3. Adjust thresholds in RepositoryComparer if needed"
    puts "   4. Re-run: bin/rails test:categorization"
  end
end
