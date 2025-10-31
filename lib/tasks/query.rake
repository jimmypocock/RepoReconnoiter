namespace :query do
  desc "Test query parser with a natural language query"
  task :parse, [ :query ] => :environment do |t, args|
    query = args[:query] || "I need a Rails background job library with retry logic and monitoring"

    puts "\n🔍 Parsing Query:"
    puts "=" * 80
    puts query
    puts "=" * 80

    parser = UserQueryParser.new
    result = parser.parse(query)

    if result[:valid]
      puts "\n✅ Query Parsed Successfully!\n"
      puts "Tech Stack:       #{result[:tech_stack]}"
      puts "Problem Domain:   #{result[:problem_domain]}"
      puts "Constraints:      #{result[:constraints].join(', ')}"
      puts "\nGitHub Queries:   #{result[:github_queries].join(' | ')}"
      puts "Query Strategy:   #{result[:query_strategy]}"
      puts "\nTokens: #{result[:input_tokens]} in / #{result[:output_tokens]} out"
      puts "Cost: $#{((result[:input_tokens] * 0.150 / 1_000_000) + (result[:output_tokens] * 0.600 / 1_000_000)).round(6)}"
    else
      puts "\n❌ Invalid Query"
      puts "Message: #{result[:validation_message]}"
    end

    puts "\n"
  end

  desc "Test multiple example queries and verify GitHub results"
  task test_examples: :environment do
    examples = [
      "I need a Rails background job library with retry logic and monitoring",
      "Looking for a Python authentication system that supports OAuth and 2FA",
      "Need a React state management library for large applications",
      "job thing",
      "best library"
    ]

    parser = UserQueryParser.new

    examples.each_with_index do |query, index|
      puts "\n" + "=" * 80
      puts "Example #{index + 1}: #{query}"
      puts "=" * 80

      result = parser.parse(query)

      if result[:valid]
        puts "✅ VALID"
        puts "  Tech Stack:     #{result[:tech_stack]}"
        puts "  Problem:        #{result[:problem_domain]}"
        puts "  Constraints:    #{result[:constraints].join(', ')}"
        puts "  GitHub Queries: #{result[:github_queries].join(' | ')}"
        puts "  Strategy:       #{result[:query_strategy]}"

        # Test the GitHub query (just first one for now)
        begin
          gh_results = Github.search(result[:github_queries].first, per_page: 5)
          puts "\n  📊 GitHub Results: #{gh_results.total_count} total repos found"
          puts "  Top 5:"
          gh_results.items.first(5).each_with_index do |repo, i|
            puts "    #{i + 1}. #{repo.full_name} (⭐ #{repo.stargazers_count})"
          end
        rescue => e
          puts "\n  ❌ GitHub Search Error: #{e.message}"
        end
      else
        puts "❌ INVALID"
        puts "  Reason: #{result[:validation_message]}"
      end
    end

    puts "\n"
  end
end
