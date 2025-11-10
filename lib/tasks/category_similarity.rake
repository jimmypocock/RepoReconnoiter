namespace :category do
  desc "Compare trigram similarity vs semantic embeddings for category matching"
  task compare_similarity: :environment do
    require "openai"

    puts "\n" + "=" * 80
    puts "CATEGORY SIMILARITY COMPARISON: Trigram vs Semantic Embeddings"
    puts "=" * 80

    # Test pairs - these represent common duplicate scenarios
    test_pairs = [
      [ "Background Jobs", "Background Job Processing" ],
      [ "PostgreSQL", "Postgres" ],
      [ "Authentication", "Auth" ],
      [ "Machine Learning", "ML" ],
      [ "Node.js", "Node" ],
      [ "Ruby on Rails", "Rails" ],
      [ "Background Job Processing", "Background Job Processng" ], # Typo
      [ "API Integration", "API Integrations" ], # Plural
      [ "Event-Driven Architecture", "Event Driven Architecture" ], # Hyphen
      [ "Data Visualization", "Authentication" ] # Completely different
    ]

    # Get embeddings for all unique category names
    puts "\nFetching embeddings from OpenAI..."
    all_names = test_pairs.flatten.uniq
    client = OpenAI::Client.new(api_key: Rails.application.credentials.openai&.api_key)

    embeddings_response = client.embeddings.create(
      model: "text-embedding-3-small",
      input: all_names
    )

    # Build embeddings lookup
    embeddings = {}
    all_names.each_with_index do |name, idx|
      embeddings[name] = embeddings_response[:data][idx][:embedding]
    end

    # Helper to calculate cosine similarity
    def cosine_similarity(vec1, vec2)
      dot_product = vec1.zip(vec2).sum { |a, b| a * b }
      magnitude1 = Math.sqrt(vec1.sum { |x| x**2 })
      magnitude2 = Math.sqrt(vec2.sum { |x| x**2 })
      dot_product / (magnitude1 * magnitude2)
    end

    # Calculate and display results
    puts "\n%-35s %-35s %10s %10s" % [ "Category 1", "Category 2", "Trigram", "Embedding" ]
    puts "-" * 95

    results = []
    test_pairs.each do |name1, name2|
      # Get trigram similarity from PostgreSQL
      trigram_score = ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array(
          [ "SELECT SIMILARITY(?, ?) AS score", name1, name2 ]
        )
      ).first["score"].to_f

      # Get embedding similarity
      embedding_score = cosine_similarity(embeddings[name1], embeddings[name2])

      results << {
        name1: name1,
        name2: name2,
        trigram: trigram_score,
        embedding: embedding_score
      }

      # Color code based on whether it would match (threshold 0.7)
      trigram_str = format("%.2f", trigram_score)
      embedding_str = format("%.2f", embedding_score)

      # Highlight when methods disagree (one passes threshold, other doesn't)
      trigram_pass = trigram_score >= 0.7
      embedding_pass = embedding_score >= 0.85 # Using 0.85 as embedding threshold

      marker = ""
      if trigram_pass != embedding_pass
        marker = " ⚠️  " # Methods disagree
      end

      puts "%-35s %-35s %10s %10s%s" % [
        name1[0..34],
        name2[0..34],
        trigram_str,
        embedding_str,
        marker
      ]
    end

    # Summary analysis
    puts "\n" + "=" * 80
    puts "ANALYSIS"
    puts "=" * 80

    puts "\nTrigram Similarity (pg_trgm):"
    puts "  • Best for: typos, character-level similarity"
    puts "  • Threshold: 0.7"
    puts "  • Misses: semantic matches, abbreviations, word additions"

    puts "\nSemantic Embeddings (OpenAI):"
    puts "  • Best for: semantic meaning, abbreviations, variations"
    puts "  • Threshold: 0.85 (cosine similarity)"
    puts "  • Cost: ~$0.000002 per comparison (virtually free)"
    puts "  • Latency: One-time batch fetch, then instant local comparison"

    # Count disagreements
    disagreements = results.select do |r|
      (r[:trigram] >= 0.7) != (r[:embedding] >= 0.85)
    end

    puts "\nDisagreements: #{disagreements.count} of #{results.count}"
    disagreements.each do |r|
      puts "  • '#{r[:name1]}' vs '#{r[:name2]}'"
      puts "    Trigram: #{format('%.2f', r[:trigram])} | Embedding: #{format('%.2f', r[:embedding])}"
    end

    # Calculate embedding cost
    total_tokens = embeddings_response[:usage][:total_tokens]
    cost_per_million = 0.02 # text-embedding-3-small pricing
    total_cost = (total_tokens / 1_000_000.0) * cost_per_million

    puts "\nEmbedding API Cost for this test:"
    puts "  • Tokens: #{total_tokens}"
    puts "  • Cost: $#{format('%.6f', total_cost)}"

    puts "\n" + "=" * 80
  end
end
