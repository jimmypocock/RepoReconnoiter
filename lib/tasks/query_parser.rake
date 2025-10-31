namespace :query do
  desc "Test query parser with a natural language query"
  task :parse, [ :query ] => :environment do |t, args|
    query = args[:query] || "I need a Rails background job library with retry logic and monitoring"

    puts "\n🔍 Parsing Query:"
    puts "=" * 80
    puts query
    puts "=" * 80

    parser = QueryParserService.new
    result = parser.parse(query)

    if result[:valid]
      puts "\n✅ Query Parsed Successfully!\n"
      puts "Tech Stack:       #{result[:tech_stack]}"
      puts "Problem Domain:   #{result[:problem_domain]}"
      puts "Constraints:      #{result[:constraints].join(', ')}"
      puts "\nGitHub Query:     #{result[:github_query]}"
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

    parser = QueryParserService.new

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
        puts "  GitHub Query:   #{result[:github_query]}"

        # Test the GitHub query
        begin
          gh_results = GithubService.search(result[:github_query], per_page: 5)
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

  desc "Test and refine a single query iteratively"
  task :refine, [ :query ] => :environment do |t, args|
    query = args[:query] || "I need a Rails background job library with retry logic"

    parser = QueryParserService.new

    puts "\n" + "=" * 80
    puts "🔬 QUERY REFINEMENT SESSION"
    puts "=" * 80
    puts "User Query: #{query}"
    puts "=" * 80

    result = parser.parse(query)

    puts "\n📋 PARSED DATA:"
    puts "  Tech Stack:     #{result[:tech_stack]}"
    puts "  Problem:        #{result[:problem_domain]}"
    puts "  Constraints:    #{result[:constraints].join(', ')}"
    puts "\n🔍 GITHUB QUERY:"
    puts "  #{result[:github_query]}"

    # Test the query
    begin
      gh_results = GithubService.search(result[:github_query], per_page: 10)

      puts "\n📊 RESULTS: #{gh_results.total_count} repos found\n"
      puts "Top 10:"
      gh_results.items.first(10).each_with_index do |repo, i|
        puts "  #{i + 1}. #{repo.full_name}"
        puts "     ⭐ #{repo.stargazers_count} | 🔧 #{repo.language || 'N/A'}"
        puts "     #{repo.description&.slice(0, 80)}..."
        puts ""
      end

      puts "\n💭 EVALUATION QUESTIONS:"
      puts "  1. Are these the right repos for: '#{query}'?"
      puts "  2. Is Sidekiq/Good Job/Delayed Job in the top 5 (if Rails job query)?"
      puts "  3. Are there irrelevant results we need to filter out?"
      puts "  4. What would make this query better?"

    rescue => e
      puts "\n❌ GitHub Search Failed: #{e.message}"
      puts "\n🔧 DEBUG: Try this query manually at:"
      puts "   https://github.com/search?q=#{URI.encode_www_form_component(result[:github_query])}"
    end

    puts "\n" + "=" * 80
  end
end
