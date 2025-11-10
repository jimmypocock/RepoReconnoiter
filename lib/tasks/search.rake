namespace :search do
  desc "Validate comprehensive search functionality with test queries"
  task validate: :environment do
    puts "\n" + "="*80
    puts "COMPREHENSIVE SEARCH VALIDATION"
    puts "="*80 + "\n"

    # Test queries organized by category
    test_queries = {
      "Technology Searches" => [
        "ruby",
        "python",
        "rust",
        "rails",
        "node",
        "go"
      ],
      "Problem Domain Searches" => [
        "background jobs",
        "authentication",
        "game",
        "icon",
        "state management"
      ],
      "Partial/Fuzzy Searches" => [
        "astro",
        "auth",
        "job",
        "scien"
      ],
      "Case Sensitivity Tests" => [
        "Ruby",
        "RAILS",
        "Python"
      ],
      "Multi-word Searches" => [
        "rails background",
        "game engine",
        "python library"
      ]
    }

    total_tests = 0
    total_results = 0

    test_queries.each do |category, queries|
      puts "\n#{category}:"
      puts "-" * 80

      queries.each do |query|
        results = Comparison.search(query)
        total_tests += 1
        total_results += results.size

        status = results.any? ? "✅" : "❌"
        puts "#{status} '#{query}' → #{results.size} result(s)"

        if results.any?
          # Show top 3 results with match reason
          results.limit(3).each do |c|
            match_reasons = []
            match_reasons << "user_query" if c.user_query&.downcase&.include?(query.downcase)
            match_reasons << "technologies" if c.technologies&.downcase&.include?(query.downcase)
            match_reasons << "problem_domains" if c.problem_domains&.downcase&.include?(query.downcase)

            # Check category match
            if c.categories.any? { |cat| cat.name.downcase.include?(query.downcase) }
              match_reasons << "category"
            end

            puts "     → \"#{c.user_query}\" (matched: #{match_reasons.join(', ')})"
          end
        end
      end
    end

    puts "\n" + "="*80
    puts "SUMMARY"
    puts "="*80
    puts "Total searches tested: #{total_tests}"
    puts "Total results found: #{total_results}"
    puts "Average results per search: #{(total_results.to_f / total_tests).round(2)}"
    puts "Searches with 0 results: #{test_queries.values.flatten.count { |q| Comparison.search(q).size == 0 }}"
    puts "\n"
  end

  desc "Test a specific search query"
  task :test, [ :query ] => :environment do |_t, args|
    query = args[:query]

    if query.blank?
      puts "Usage: bin/rails search:test[\"your search term\"]"
      exit 1
    end

    puts "\n" + "="*80
    puts "SEARCH QUERY: '#{query}'"
    puts "="*80 + "\n"

    results = Comparison.search(query)

    puts "Found #{results.size} result(s):\n\n"

    results.each_with_index do |comparison, index|
      puts "#{index + 1}. #{comparison.user_query}"
      puts "   ID: #{comparison.id}"
      puts "   Technologies: #{comparison.technologies}"
      puts "   Problem Domains: #{comparison.problem_domains}"
      puts "   Categories: #{comparison.categories.pluck(:name).join(', ')}"

      # Show why it matched
      match_reasons = []
      match_reasons << "✓ user_query" if comparison.user_query&.downcase&.include?(query.downcase)
      match_reasons << "✓ technologies" if comparison.technologies&.downcase&.include?(query.downcase)
      match_reasons << "✓ problem_domains" if comparison.problem_domains&.downcase&.include?(query.downcase)

      if comparison.categories.any? { |cat| cat.name.downcase.include?(query.downcase) }
        matching_cats = comparison.categories.select { |cat| cat.name.downcase.include?(query.downcase) }
        match_reasons << "✓ categories (#{matching_cats.map(&:name).join(', ')})"
      end

      puts "   Matched: #{match_reasons.join(' | ')}"
      puts "\n"
    end

    puts "="*80 + "\n"
  end

  desc "Analyze search coverage across all comparisons"
  task coverage: :environment do
    puts "\n" + "="*80
    puts "SEARCH COVERAGE ANALYSIS"
    puts "="*80 + "\n"

    total_comparisons = Comparison.count
    puts "Total comparisons: #{total_comparisons}\n\n"

    # Analyze field population
    puts "Field Population:"
    puts "-" * 80
    puts "user_query:      #{Comparison.where.not(user_query: nil).count}/#{total_comparisons} (#{(Comparison.where.not(user_query: nil).count.to_f / total_comparisons * 100).round(1)}%)"
    puts "technologies:    #{Comparison.where.not(technologies: nil).count}/#{total_comparisons} (#{(Comparison.where.not(technologies: nil).count.to_f / total_comparisons * 100).round(1)}%)"
    puts "problem_domains: #{Comparison.where.not(problem_domains: nil).count}/#{total_comparisons} (#{(Comparison.where.not(problem_domains: nil).count.to_f / total_comparisons * 100).round(1)}%)"

    # Category coverage
    comparisons_with_categories = Comparison.joins(:categories).distinct.count
    puts "categories:      #{comparisons_with_categories}/#{total_comparisons} (#{(comparisons_with_categories.to_f / total_comparisons * 100).round(1)}%)"

    puts "\n"

    # Top categories
    puts "Top 10 Categories (by comparison count):"
    puts "-" * 80
    Category.joins(:comparison_categories)
            .group(:name)
            .order("COUNT(comparison_categories.id) DESC")
            .limit(10)
            .count
            .each_with_index do |(name, count), index|
      puts "#{index + 1}. #{name}: #{count} comparisons"
    end

    puts "\n" + "="*80 + "\n"
  end

  desc "Benchmark search performance"
  task benchmark: :environment do
    require "benchmark"

    puts "\n" + "="*80
    puts "SEARCH PERFORMANCE BENCHMARK"
    puts "="*80 + "\n"

    test_queries = [ "ruby", "python", "background jobs", "auth", "game engine" ]

    puts "Testing #{test_queries.count} queries...\n\n"

    results = Benchmark.bm(20) do |x|
      test_queries.each do |query|
        x.report("search('#{query}')") do
          100.times { Comparison.search(query).to_a }
        end
      end
    end

    puts "\n" + "="*80 + "\n"
  end
end
