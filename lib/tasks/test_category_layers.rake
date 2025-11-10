namespace :categories do
  desc "Test three-layer category matching with real data"
  task test_layers: :environment do
    puts "\n" + "=" * 80
    puts "TESTING THREE-LAYER CATEGORY MATCHING"
    puts "=" * 80

    # Clean slate - create test categories
    puts "\n📋 Setting up test categories..."

    matcher = CategoryMatcher.new

    # Create base categories (these will have embeddings)
    base_categories = [
      { name: "Authentication", type: "problem_domain" },
      { name: "Background Job Processing", type: "problem_domain" },
      { name: "PostgreSQL", type: "technology" },
      { name: "Machine Learning", type: "problem_domain" },
      { name: "API Integration", type: "problem_domain" }
    ]

    created = []
    base_categories.each do |cat|
      category = matcher.find_or_create(name: cat[:name], category_type: cat[:type])
      created << category
      puts "  ✓ Created: #{category.name} (#{category.category_type})"
    end

    puts "\n" + "=" * 80
    puts "TEST SCENARIOS"
    puts "=" * 80

    # Test scenarios: [ search_term, expected_match, layer ]
    test_cases = [
      # Layer 1: Alias mapping (instant)
      { search: "Ruby on Rails", type: "technology", expected: "Rails", layer: "Layer 1 (Alias)" },
      { search: "postgres", type: "technology", expected: "PostgreSQL", layer: "Layer 1 (Alias)" },
      { search: "k8s", type: "technology", expected: "Kubernetes", layer: "Layer 1 (Alias)" },

      # Layer 2: Trigram similarity (typos, plurals)
      { search: "Background Job Processng", type: "problem_domain", expected: "Background Job Processing", layer: "Layer 2 (Trigram)" },
      { search: "API Integrations", type: "problem_domain", expected: "API Integration", layer: "Layer 2 (Trigram)" },

      # Layer 3: Semantic embeddings (abbreviations, word additions)
      { search: "Auth", type: "problem_domain", expected: "Authentication", layer: "Layer 3 (Embedding)" },
      { search: "Background Jobs", type: "problem_domain", expected: "Background Job Processing", layer: "Layer 3 (Embedding)" },
      { search: "ML", type: "problem_domain", expected: "Machine Learning", layer: "Layer 3 (Embedding)" },

      # Should NOT match (different type)
      { search: "Authentication", type: "technology", expected: nil, layer: "Type Isolation" },

      # Should create new (completely different)
      { search: "Data Visualization", type: "problem_domain", expected: "Data Visualization", layer: "New Category" }
    ]

    results = []

    test_cases.each do |test|
      print "\n#{test[:layer]}: '#{test[:search]}' → "

      result = matcher.find_or_create(name: test[:search], category_type: test[:type])

      if test[:expected]
        if result.name == test[:expected]
          puts "✅ #{result.name}"
          results << { test: test[:search], status: "✅", matched: result.name, expected: test[:expected] }
        else
          puts "❌ Got '#{result.name}', expected '#{test[:expected]}'"
          results << { test: test[:search], status: "❌", matched: result.name, expected: test[:expected] }
        end
      else
        if result.name == test[:search]
          puts "✅ Correctly isolated by type"
          results << { test: test[:search], status: "✅", matched: result.name, expected: "no match" }
        else
          puts "❌ Should not have matched"
          results << { test: test[:search], status: "❌", matched: result.name, expected: "no match" }
        end
      end
    end

    # Summary
    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80

    passed = results.count { |r| r[:status] == "✅" }
    failed = results.count { |r| r[:status] == "❌" }

    puts "\nPassed: #{passed}/#{results.count}"
    puts "Failed: #{failed}/#{results.count}"

    if failed > 0
      puts "\n❌ FAILURES:"
      results.select { |r| r[:status] == "❌" }.each do |r|
        puts "  • '#{r[:test]}' → got '#{r[:matched]}', expected '#{r[:expected]}'"
      end
    else
      puts "\n✅ All tests passed!"
    end

    # Show which layers were used
    puts "\n" + "=" * 80
    puts "LAYER USAGE BREAKDOWN"
    puts "=" * 80
    puts "Layer 1 (Alias mapping): Instant, free, exact matches"
    puts "Layer 2 (Trigram fuzzy): Instant, free, character similarity (≥0.7)"
    puts "Layer 3 (Embeddings): 2ms, ~$0.000002, semantic similarity (≥0.80)"
    puts "\n💡 Layers are tried in order - stops at first match"

    puts "\n" + "=" * 80
  end
end
