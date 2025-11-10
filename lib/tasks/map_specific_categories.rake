namespace :categories do
  desc "Map 18 overly-specific categories to canonical equivalents"
  task map_specific: :environment do
    puts "\n" + "=" * 100
    puts "MAP SPECIFIC CATEGORIES TO CANONICAL"
    puts "=" * 100

    # Define mappings: specific category name → canonical category name
    mappings = {
      # Map to Rails
      "Rails Wrapper" => { to: "Rails", type: "technology" },
      "Ruby on Rails Wrapper" => { to: "Rails", type: "technology" },

      # Map to Icons
      "Icon Font Generation" => { to: "Icons", type: "problem_domain" },
      "SVG Icon Generation" => { to: "Icons", type: "problem_domain" },

      # Map to Session Management
      "HTTP Session Management" => { to: "Session Management", type: "problem_domain" },

      # Map to Data Processing
      "Data Sync" => { to: "Data Processing", type: "architecture_pattern" },

      # Map to Artificial Intelligence
      "AI Knowledge Base" => { to: "Artificial Intelligence", type: "problem_domain" },
      "AI Memory Management" => { to: "Artificial Intelligence", type: "problem_domain" },
      "Knowledge Graph Management" => { to: "Artificial Intelligence", type: "problem_domain" },
      "Model Context Protocol" => { to: "Artificial Intelligence", type: "problem_domain" },
      "Multi-Agent System" => { to: "Artificial Intelligence", type: "problem_domain" },
      "Retrieval-Augmented Generation" => { to: "Artificial Intelligence", type: "problem_domain" },

      # Map to Backend Applications
      "HTTP Routing Framework" => { to: "Backend Applications", type: "problem_domain" },
      "High-Performance Web Framework" => { to: "Backend Applications", type: "problem_domain" },

      # Map to Frontend Frameworks
      "Material Design Integration" => { to: "Frontend Frameworks", type: "architecture_pattern" },

      # Map to Dev Ops Tools
      "Registry Service" => { to: "Dev Ops Tools", type: "problem_domain" },

      # Map to Developer Tools
      "Shell History Management" => { to: "Developer Tools", type: "architecture_pattern" },

      # Map to Security
      "Zero Trust Security" => { to: "Security", type: "problem_domain" },
    }

    puts "\nMappings to apply:"
    mappings.each do |from_name, to_info|
      puts "  • #{from_name} → #{to_info[:to]} (#{to_info[:type]})"
    end

    puts "\n" + "-" * 100

    # Confirm (unless SKIP_CONFIRM=1)
    unless ENV["SKIP_CONFIRM"] == "1"
      print "\nProceed with mappings? (y/n): "
      response = STDIN.gets&.chomp&.downcase
      unless response == "y"
        puts "\nCancelled."
        exit
      end
    end

    # Execute mappings
    puts "\n🔄 Migrating associations..."

    migrated_count = 0
    mappings.each do |from_name, to_info|
      # Find the specific category
      from_cat = Category.find_by(name: from_name)

      unless from_cat
        puts "  ⚠️  #{from_name} not found, skipping"
        next
      end

      # Find the canonical category
      to_cat = Category.find_by(name: to_info[:to], category_type: to_info[:type])

      unless to_cat
        puts "  ❌ Target category '#{to_info[:to]}' not found!"
        next
      end

      # Migrate associations
      repo_count = from_cat.repository_categories.count
      comp_count = from_cat.comparison_categories.count

      if repo_count > 0 || comp_count > 0
        # For repository associations, handle duplicates
        from_cat.repository_categories.each do |repo_cat|
          # Check if repository already has the canonical category
          existing = RepositoryCategory.find_by(repository_id: repo_cat.repository_id, category_id: to_cat.id)

          if existing
            # Repository already has canonical category, just delete this one
            repo_cat.destroy
          else
            # Safe to update
            repo_cat.update!(category_id: to_cat.id)
          end
        end

        # For comparison associations, handle duplicates
        from_cat.comparison_categories.each do |comp_cat|
          # Check if comparison already has the canonical category
          existing = ComparisonCategory.find_by(comparison_id: comp_cat.comparison_id, category_id: to_cat.id)

          if existing
            # Comparison already has canonical category, just delete this one
            comp_cat.destroy
          else
            # Safe to update
            comp_cat.update!(category_id: to_cat.id)
          end
        end

        # Delete the specific category
        from_cat.destroy

        puts "  ✅ Migrated #{from_name} → #{to_info[:to]} (#{repo_count} repos, #{comp_count} comps)"
        migrated_count += 1
      else
        # No associations, just delete
        from_cat.destroy
        puts "  ✅ Deleted #{from_name} (no associations)"
        migrated_count += 1
      end
    end

    # Summary
    puts "\n" + "=" * 100
    puts "✅ MAPPING COMPLETE"
    puts "=" * 100
    puts "\nMapped: #{migrated_count} categories"
    puts "Final count: #{Category.count} categories"
    puts "Repository associations: #{RepositoryCategory.count}"
    puts "Comparison associations: #{ComparisonCategory.count}"
    puts "\n💡 Next step: bin/rails categories:dump_seeds"
    puts "=" * 100
  end
end
