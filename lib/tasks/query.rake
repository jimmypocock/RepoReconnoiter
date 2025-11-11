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
end
