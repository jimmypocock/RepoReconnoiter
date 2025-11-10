namespace :categories do
  desc "Run comprehensive 45-scenario category matching test"
  task test_matrix: :environment do
    puts "\n" + "=" * 100
    puts "COMPREHENSIVE CATEGORY MATCHING TEST - 44 SCENARIOS"
    puts "=" * 100

    matcher = CategoryMatcher.new

    # Define 45 real-world test scenarios (no maturity - now a repo attribute)
    scenarios = [
      # ==========================================
      # TECHNOLOGY NAME VARIATIONS (15 scenarios)
      # ==========================================
      { category: "Technology Abbreviations", input: "js", type: "technology", expect: "JavaScript" },
      { category: "Technology Abbreviations", input: "ts", type: "technology", expect: "TypeScript" },
      { category: "Technology Abbreviations", input: "pg", type: "technology", expect: "PostgreSQL" },
      { category: "Technology Abbreviations", input: "postgres", type: "technology", expect: "PostgreSQL" },
      { category: "Technology Abbreviations", input: "k8s", type: "technology", expect: "Kubernetes" },

      { category: "Framework Variants", input: "reactjs", type: "technology", expect: "React" },
      { category: "Framework Variants", input: "vuejs", type: "technology", expect: "Vue.js" },
      { category: "Framework Variants", input: "nodejs", type: "technology", expect: "Node.js" },
      { category: "Framework Variants", input: "Ruby on Rails", type: "technology", expect: "Rails" },

      { category: "Casing Variants", input: "PYTHON", type: "technology", expect: "Python" },
      { category: "Casing Variants", input: "javascript", type: "technology", expect: "JavaScript" },
      { category: "Casing Variants", input: "rust", type: "technology", expect: "Rust" },

      { category: "Typos/Misspellings", input: "Postgress", type: "technology", expect: "PostgreSQL" },
      { category: "Typos/Misspellings", input: "Kubernetis", type: "technology", expect: "Kubernetes" },
      { category: "Typos/Misspellings", input: "Javasript", type: "technology", expect: "JavaScript" },

      # ==========================================
      # PROBLEM DOMAIN VARIATIONS (15 scenarios)
      # ==========================================
      { category: "Problem Domain Abbrev", input: "auth", type: "problem_domain", expect: "Authentication" },
      { category: "Problem Domain Abbrev", input: "ml", type: "problem_domain", expect: "Machine Learning" },
      { category: "Problem Domain Abbrev", input: "AI", type: "problem_domain", expect: "Artificial Intelligence" },

      { category: "Plural/Singular", input: "Background Jobs", type: "problem_domain", expect: "Background Job Processing" },
      { category: "Plural/Singular", input: "API Integrations", type: "problem_domain", expect: "API Integration" },
      { category: "Plural/Singular", input: "Payment Process", type: "problem_domain", expect: "Payment Processing" },

      { category: "Word Variations", input: "Cache", type: "problem_domain", expect: "Caching" },
      { category: "Word Variations", input: "Caching", type: "problem_domain", expect: "Caching" },
      { category: "Word Variations", input: "Performance", type: "problem_domain", expect: "Performance" },

      { category: "Typos", input: "Machne Learning", type: "problem_domain", expect: "Machine Learning" },
      { category: "Typos", input: "Autentication", type: "problem_domain", expect: "Authentication" },
      { category: "Typos", input: "Backgrond Job Processing", type: "problem_domain", expect: "Background Job Processing" },

      { category: "Case Variants", input: "api integration", type: "problem_domain", expect: "API Integration" },
      { category: "Case Variants", input: "MACHINE LEARNING", type: "problem_domain", expect: "Machine Learning" },
      { category: "Case Variants", input: "payment processing", type: "problem_domain", expect: "Payment Processing" },

      # ==========================================
      # ARCHITECTURE PATTERN VARIATIONS (10 scenarios)
      # ==========================================
      { category: "Hyphen Variants", input: "Event Driven Architecture", type: "architecture_pattern", expect: "Event-Driven Architecture" },
      { category: "Hyphen Variants", input: "API First Design", type: "architecture_pattern", expect: "API-First Design" },

      { category: "With/Without 'Architecture'", input: "Event-Driven", type: "architecture_pattern", expect: "Event-Driven Architecture" },
      { category: "With/Without 'Architecture'", input: "Multithreaded", type: "architecture_pattern", expect: "Multithreaded Architecture" },

      { category: "Different Phrasings", input: "Serverless", type: "architecture_pattern", expect: "Serverless Architecture" },
      { category: "Different Phrasings", input: "CLI Tools", type: "architecture_pattern", expect: "CLI Tools" },
      { category: "Different Phrasings", input: "Developer Tools", type: "architecture_pattern", expect: "Developer Tools" },
      { category: "Different Phrasings", input: "Command Line Tools", type: "architecture_pattern", expect: "CLI Tools" },

      { category: "Typos", input: "Evnt-Driven Architecture", type: "architecture_pattern", expect: "Event-Driven Architecture" },
      { category: "Typos", input: "Multithreded Architecture", type: "architecture_pattern", expect: "Multithreaded Architecture" },

      # ==========================================
      # EDGE CASES (5 scenarios)
      # ==========================================
      { category: "Type Isolation", input: "Testing", type: "technology", expect: "Testing", note: "Exists as both tech and problem_domain" },

      { category: "New Categories", input: "Blockchain Technology", type: "technology", expect: "Blockchain Technology", note: "Should create new" },
      { category: "New Categories", input: "Real-Time Communication", type: "problem_domain", expect: "Real-Time Communication", note: "Should create new" },
      { category: "New Categories", input: "Microservices Architecture", type: "architecture_pattern", expect: "Microservices Architecture", note: "Should create new" }
    ]

    # Run tests
    results = {
      passed: 0,
      failed: 0,
      details: []
    }

    puts "\n%-30s %-40s %-25s %-30s %s" % [ "CATEGORY", "INPUT", "TYPE", "EXPECTED", "RESULT" ]
    puts "-" * 130

    scenarios.each_with_index do |scenario, idx|
      result = matcher.find_or_create(name: scenario[:input], category_type: scenario[:type])

      success = result.name == scenario[:expect]
      status = success ? "✅" : "❌"

      if success
        results[:passed] += 1
      else
        results[:failed] += 1
        results[:details] << {
          input: scenario[:input],
          type: scenario[:type],
          expected: scenario[:expect],
          actual: result.name
        }
      end

      # Truncate long strings for display
      input_display = scenario[:input].ljust(40)[0..39]
      expected_display = scenario[:expect].ljust(25)[0..24]
      actual_display = result.name.ljust(30)[0..29]

      puts "%-30s %-40s %-25s %-30s %s" % [
        scenario[:category],
        input_display,
        scenario[:type],
        expected_display,
        "#{status} #{actual_display}"
      ]
    end

    # Summary
    puts "\n" + "=" * 100
    puts "SUMMARY"
    puts "=" * 100
    puts "\nTotal scenarios: #{scenarios.count}"
    puts "Passed: #{results[:passed]} (#{(results[:passed] / scenarios.count.to_f * 100).round(1)}%)"
    puts "Failed: #{results[:failed]} (#{(results[:failed] / scenarios.count.to_f * 100).round(1)}%)"

    if results[:failed] > 0
      puts "\n" + "-" * 100
      puts "FAILURES DETAIL"
      puts "-" * 100
      results[:details].each do |detail|
        puts "\n❌ Input: '#{detail[:input]}' (#{detail[:type]})"
        puts "   Expected: '#{detail[:expected]}'"
        puts "   Got:      '#{detail[:actual]}'"
      end
    else
      puts "\n🎉 ALL TESTS PASSED!"
    end

    # Layer usage analysis
    puts "\n" + "=" * 100
    puts "RECOMMENDATION"
    puts "=" * 100

    if results[:passed] >= 45 # 90% pass rate
      puts "✅ Three-layer matching is working well!"
      puts "   • Thresholds are properly calibrated"
      puts "   • Alias mapping is comprehensive"
      puts "   • Embedding semantic matching fills the gaps"
    elsif results[:passed] >= 40 # 80% pass rate
      puts "⚠️  Good results, but some tuning recommended"
      puts "   • Consider lowering embedding threshold (currently #{CategoryMatcher::EMBEDDING_THRESHOLD})"
      puts "   • Review failed cases for missing aliases"
    else
      puts "❌ Needs improvement"
      puts "   • Review threshold settings"
      puts "   • Add more aliases to Layer 1"
      puts "   • Consider adjusting embedding threshold"
    end

    puts "\n" + "=" * 100
  end
end
