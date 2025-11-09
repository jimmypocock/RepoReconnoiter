namespace :test_queries do
  desc "Test search quality with diverse queries"
  task :run, [ :count ] => :environment do |_t, args|
    count = args[:count]&.to_i || 10

    test_queries = [
      "Go state management library for web applications",
      "Elixir background job processing with retry logic",
      "Rust async HTTP client for REST APIs",
      "Python data validation library with type hints",
      "JavaScript date manipulation library without moment.js",
      "TypeScript form validation for React",
      "Ruby PDF generation library for invoices",
      "Python library for training transformer models",
      "React Server Components framework for Next.js alternatives",
      "Go Kubernetes operator framework",
      "Python ETL library for data pipelines",
      "Rust game engine for 2D platformers",
      "Swift networking layer for iOS apps",
      "Python computer vision library for object detection",
      "JavaScript WebSocket library for real-time chat"
    ]

    results = []

    test_queries.first(count).each_with_index do |query, i|
      puts "\n" + "="*60
      puts "#{i + 1}/#{count}: #{query}"
      puts "="*60

      parser = UserQueryParser.new
      parsed = parser.parse(query)

      next unless parsed[:valid]

      queries = parsed[:github_queries]
      strategy = parsed[:query_strategy]

      puts "Strategy: #{strategy}"
      puts "Queries (#{queries.size}):"
      queries.each_with_index do |q, j|
        puts "  #{j + 1}. #{q}"
      end

      # Quick GitHub check for first query
      github = Github.new
      first_query_results = github.search(queries.first, per_page: 30)

      puts "\nGitHub Results:"
      puts "  First query returned: #{first_query_results.items.count} repos"

      results << {
        query: query,
        strategy: strategy,
        num_queries: queries.size,
        github_queries: queries,
        first_query_count: first_query_results.items.count
      }

      sleep 1  # Rate limit courtesy
    end

    puts "\n\n" + "="*60
    puts "SUMMARY"
    puts "="*60
    single_query = results.count { |r| r[:strategy] == "single" }
    multi_query = results.count { |r| r[:strategy] == "multi" }

    puts "Single query: #{single_query} (#{(single_query * 100.0 / results.size).round}%)"
    puts "Multi query: #{multi_query} (#{(multi_query * 100.0 / results.size).round}%)"
    puts "\nQuery count distribution:"
    results.group_by { |r| r[:num_queries] }.sort.each do |num, items|
      puts "  #{num} queries: #{items.size} searches"
    end

    puts "\nAverage repos found (first query): #{(results.sum { |r| r[:first_query_count] } / results.size.to_f).round(1)}"
  end
end
