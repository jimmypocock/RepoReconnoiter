namespace :comparison do
  desc "Create a new comparison (parse → fetch → analyze → compare)"
  desc "Usage: QUERY='your query here' bin/rails comparisons:create"
  task create: :environment do
    query = ENV["QUERY"]

    unless query.present?
      puts "\n" + "=" * 80
      puts "🏆 CREATE COMPARISON"
      puts "=" * 80
      puts "\n❌ No query provided!"
      puts "\n📖 Usage:"
      puts "  QUERY='your query here' bin/rails comparisons:create"
      puts "\n💡 Examples:"
      puts "  QUERY='Rails background job library with retry logic' bin/rails comparisons:create"
      puts "  QUERY='Python ORM for PostgreSQL' bin/rails comparisons:create"
      puts "  QUERY='React state management for large apps' bin/rails comparisons:create"
      puts "\n" + "=" * 80
      puts ""
      exit
    end

    puts "\n" + "=" * 80
    puts "🏆 CREATE COMPARISON"
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
      puts "✅ Comparison creation complete"
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

  desc "Search for comparisons matching a query"
  task :search, [ :query ] => :environment do |_t, args|
    query = args[:query]

    if query.blank?
      puts "Usage: bin/rails comparisons:search[\"your search term\"]"
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
end
