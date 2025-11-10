namespace :comparisons do
  desc "Backfill comparison_categories using UserQueryParser"
  task backfill_categories: :environment do
    puts "\n" + "=" * 100
    puts "BACKFILL COMPARISON CATEGORIES"
    puts "=" * 100

    comparisons = Comparison.all
    puts "\nTotal comparisons: #{comparisons.count}"

    # Show current state
    puts "\nCurrent associations:"
    comparisons.each do |comparison|
      cat_count = comparison.comparison_categories.count
      puts "  #{comparison.id}: #{comparison.user_query.truncate(60)} (#{cat_count} categories)"
    end

    puts "\n" + "-" * 100

    # Confirm (unless SKIP_CONFIRM=1)
    unless ENV["SKIP_CONFIRM"] == "1"
      print "\nRe-parse all queries and replace category associations? (y/n): "
      response = STDIN.gets&.chomp&.downcase
      unless response == "y"
        puts "\nCancelled."
        exit
      end
    end

    # Re-parse each comparison
    puts "\n🔄 Re-parsing queries..."
    parser = UserQueryParser.new
    matcher = CategoryMatcher.new

    comparisons.each do |comparison|
      print "  Processing comparison #{comparison.id}... "

      begin
        # Parse the user query
        result = parser.parse(comparison.user_query)

        unless result[:valid]
          puts "❌ Invalid parse result"
          next
        end

        # Extract categories from parsed result
        category_names = []

        # Add tech stack categories
        if result[:tech_stack].present?
          result[:tech_stack].split(",").each do |tech|
            category_names << { name: tech.strip, type: "technology" }
          end
        end

        # Add problem domain
        if result[:problem_domain].present?
          category_names << { name: result[:problem_domain], type: "problem_domain" }
        end

        # Add architecture pattern if specified
        if result[:architecture_pattern].present?
          category_names << { name: result[:architecture_pattern], type: "architecture_pattern" }
        end

        # Find or create canonical categories
        category_ids = []
        category_names.each do |cat_info|
          category = matcher.find_or_create(
            name: cat_info[:name],
            category_type: cat_info[:type]
          )
          category_ids << category.id
        end

        # Remove duplicates
        category_ids.uniq!

        # Replace existing associations
        comparison.comparison_categories.destroy_all
        category_ids.each do |cat_id|
          comparison.comparison_categories.create!(
            category_id: cat_id,
            assigned_by: "ai"
          )
        end

        puts "✅ #{category_ids.count} categories"
      rescue => e
        puts "❌ Error: #{e.message}"
      end
    end

    # Show final state
    puts "\n" + "=" * 100
    puts "✅ BACKFILL COMPLETE"
    puts "=" * 100

    puts "\nFinal associations:"
    comparisons.reload.each do |comparison|
      puts "\nComparison #{comparison.id}: #{comparison.user_query}"
      comparison.comparison_categories.includes(:category).each do |cc|
        puts "  - #{cc.category.name} (#{cc.category.category_type})"
      end
    end

    puts "\n" + "=" * 100
  end
end
