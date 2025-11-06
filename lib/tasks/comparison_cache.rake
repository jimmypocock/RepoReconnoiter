# Helper class for testing similarity thresholds (development/testing only)
class ComparisonSimilarityTester
  class << self
    # Calculate similarity score between two queries
    # Returns: Float (0.0 - 1.0)
    def calculate_similarity(query1, query2)
      q1 = Comparison.normalize_query_string(query1)
      q2 = Comparison.normalize_query_string(query2)

      result = ActiveRecord::Base.connection.execute(
        "SELECT SIMILARITY(#{ActiveRecord::Base.connection.quote(q1)},
                          #{ActiveRecord::Base.connection.quote(q2)}) AS score"
      ).first

      result["score"].to_f
    end

    # Default test cases for threshold tuning
    # Format: [query1, query2, should_match]
    def default_test_cases
      [
        # Exact duplicates - MUST match
        [ "Rails background jobs", "Rails background jobs", true ],
        [ "React state management", "React state management", true ],

        # Near-exact (minor wording changes) - SHOULD match
        [ "rails background jobs", "Rails job processing", true ],
        [ "react state management", "React state manager", true ],
        [ "python authentication", "Python auth library", true ],

        # Same topic, different constraints - DEBATABLE
        [ "Rails background job library with retry logic", "Rails background job that doesn't require redis", true ],
        [ "Python ORM for PostgreSQL", "Python ORM for MySQL", true ],

        # Different tech stacks - MUST NOT match
        [ "rails jobs", "python django", false ],
        [ "React state management", "rails based gem for state management", false ],
        [ "Go web framework", "Node.js web framework", false ],

        # Infrastructure (language-agnostic) - SHOULD match
        [ "docker monitoring", "kubernetes monitoring", true ],

        # Different languages - MUST NOT match
        [ "golang web framework", "go http server", true ],  # Same language (Go)
        [ "Ruby authentication", "Python authentication", false ],  # Different languages

        # Typos - SHOULD match
        [ "typo example: backgrond jobs", "background jobs rails", true ]
      ]
    end

    # Test a specific threshold against test cases
    # Returns: Hash with results and accuracy metrics
    def test_threshold(threshold, test_cases)
      results = test_cases.map do |query1, query2, should_match|
        similarity = calculate_similarity(query1, query2)
        matched = similarity > threshold

        {
          query1: query1,
          query2: query2,
          similarity: similarity,
          matched: matched,
          should_match: should_match,
          correct: matched == should_match
        }
      end

      {
        threshold: threshold,
        results: results,
        accuracy: (results.count { |r| r[:correct] }.to_f / results.count * 100).round(1),
        match_count: results.count { |r| r[:matched] }
      }
    end
  end
end

namespace :comparison_cache do
  desc "Analyze real queries in database"
  task analyze_real_queries: :environment do
    comparisons = Comparison.all.order(created_at: :desc)

    if comparisons.empty?
      puts "\n❌ No comparisons in database yet. Create some first!"
      exit 1
    end

    puts "\n" + "="*80
    puts "REAL QUERY ANALYSIS"
    puts "="*80
    puts "\nTotal Comparisons: #{comparisons.count}"
    puts "\nAll Queries:"
    comparisons.each_with_index do |c, i|
      days_ago = ((Time.current - c.created_at) / 1.day).round
      time_desc = days_ago == 0 ? "today" : "#{days_ago}d ago"
      puts "  #{i + 1}. \"#{c.user_query}\" (#{c.view_count} views, #{time_desc})"
    end

    # Find potential duplicates at different thresholds
    puts "\n" + "-"*80
    puts "POTENTIAL DUPLICATES AT DIFFERENT THRESHOLDS"
    puts "(This shows WHAT WOULD HAPPEN at each threshold, not what's currently active)"
    puts "-"*80

    [ 0.3, 0.5, 0.8, Comparison::SIMILARITY_THRESHOLD ].uniq.sort.each do |threshold|
      puts "\n📊 Threshold: #{threshold}"
      duplicates = []

      comparisons.each_with_index do |c1, i|
        comparisons.each_with_index do |c2, j|
          next if i >= j  # Skip same comparison and avoid duplicates

          similarity = ComparisonSimilarityTester.calculate_similarity(c1.user_query, c2.user_query)

          if similarity > threshold
            duplicates << {
              query1: c1.user_query,
              query2: c2.user_query,
              similarity: similarity
            }
          end
        end
      end

      if duplicates.empty?
        puts "  No duplicates found (no cache hits)"
      else
        puts "  Found #{duplicates.count} potential duplicate(s):"
        duplicates.each do |d|
          puts "    • #{(d[:similarity] * 100).round}% - \"#{d[:query1]}\" ≈ \"#{d[:query2]}\""
        end
      end
    end

    puts "\n" + "="*80
  end

  desc "Test similarity threshold with sample queries"
  task test_threshold: :environment do
    test_cases = ComparisonSimilarityTester.default_test_cases
    thresholds = [ 0.3, 0.4, 0.5, 0.6, 0.7 ]

    puts "\n" + "="*80
    puts "SIMILARITY THRESHOLD TESTING"
    puts "="*80

    thresholds.each do |threshold|
      puts "\n📊 Threshold: #{threshold}"
      puts "-" * 80

      analysis = ComparisonSimilarityTester.test_threshold(threshold, test_cases)

      analysis[:results].each do |r|
        status = case [ r[:matched], r[:correct] ]
        when [ true, true ] then "✅ CORRECT MATCH"
        when [ false, true ] then "✅ CORRECT SKIP"
        when [ true, false ] then "❌ FALSE POSITIVE"
        else "❌ FALSE NEGATIVE"
        end

        score = (r[:similarity] * 100).round.to_s.rjust(3)
        puts "  #{status} (#{score}%): '#{r[:query1]}' vs '#{r[:query2]}'"
      end

      puts "\n  📈 Accuracy: #{analysis[:accuracy]}% (#{analysis[:match_count]}/#{test_cases.count} matched)"
    end

    puts "\n" + "="*80
    puts "💡 Current threshold: #{Comparison::SIMILARITY_THRESHOLD}"
    puts "   Set via: COMPARISON_SIMILARITY_THRESHOLD env var"
    puts "="*80
  end

  desc "Test specific query similarity"
  task :test_query, [ :query1, :query2 ] => :environment do |t, args|
    unless args[:query1] && args[:query2]
      puts "\n❌ Usage: bin/rails comparison_cache:test_query['query1','query2']"
      puts "Example: bin/rails comparison_cache:test_query['rails jobs','Rails background processing']"
      exit 1
    end

    similarity = ComparisonSimilarityTester.calculate_similarity(args[:query1], args[:query2])
    threshold = Comparison::SIMILARITY_THRESHOLD

    puts "\n" + "="*80
    puts "QUERY SIMILARITY TEST"
    puts "="*80
    puts "\nQuery 1: #{args[:query1]}"
    puts "Query 2: #{args[:query2]}"
    puts "\nSimilarity Score: #{(similarity * 100).round(1)}%"
    puts "Current Threshold: #{(threshold * 100).round(1)}%"
    puts "\n#{similarity > threshold ? '✅ WOULD MATCH (cached)' : '❌ WOULD NOT MATCH (new comparison)'}"
    puts "="*80
  end

  desc "Show cache statistics"
  task stats: :environment do
    total = Comparison.count
    cached = Comparison.cached.count
    stale = Comparison.where("created_at <= ?", Comparison::CACHE_TTL_DAYS.days.ago).count

    puts "\n" + "="*80
    puts "COMPARISON CACHE STATISTICS"
    puts "="*80
    puts "\nTotal Comparisons: #{total}"
    puts "  Cached (fresh): #{cached} (#{(cached.to_f / total * 100).round(1)}%)" if total > 0
    puts "  Stale: #{stale} (#{(stale.to_f / total * 100).round(1)}%)" if total > 0
    puts "\nCache Configuration:"
    puts "  TTL: #{Comparison::CACHE_TTL_DAYS} days"
    puts "  Similarity Threshold: #{(Comparison::SIMILARITY_THRESHOLD * 100).round(1)}%"
    puts "\nMost Viewed:"
    Comparison.order(view_count: :desc).limit(5).each_with_index do |c, i|
      days_ago = ((Time.current - c.created_at) / 1.day).round
      time_desc = days_ago == 0 ? "today" : "#{days_ago} days ago"
      puts "  #{i + 1}. \"#{c.user_query}\" (#{c.view_count} views, #{time_desc})"
    end
    puts "="*80
  end
end
