namespace :categories do
  desc "Migrate to canonical 101 categories, preserving all associations"
  task migrate_to_canonical: :environment do
    puts "\n" + "=" * 100
    puts "MIGRATE TO CANONICAL CATEGORIES"
    puts "=" * 100

    # Load canonical categories from seeds file to get the list
    canonical_categories = []
    seeds_content = File.read(Rails.root.join("db", "seeds", "categories.rb"))

    # Extract all slug + type combinations from seeds file
    seeds_content.scan(/find_or_initialize_by\(slug: '([^']+)', category_type: '([^']+)'\)/).each do |slug, type|
      canonical_categories << { slug: slug, category_type: type }
    end

    puts "\nCanonical categories: #{canonical_categories.count}"
    puts "Current database: #{Category.count}"

    # Find categories NOT in canonical list
    extra_categories = Category.where.not(
      canonical_categories.map { |c| "slug = '#{c[:slug]}' AND category_type = '#{c[:category_type]}'" }.join(" OR ")
    )

    puts "Extra categories to migrate: #{extra_categories.count}"

    if extra_categories.empty?
      puts "\n✅ No migration needed - all categories are canonical!"
      exit
    end

    # Show what will be migrated
    puts "\n📋 MIGRATION PLAN"
    puts "-" * 100

    migration_plan = []
    extra_categories.each do |extra|
      repo_count = extra.repository_categories.count
      comparison_count = extra.comparison_categories.count

      next if repo_count == 0 && comparison_count == 0

      # Find best canonical match using CategoryMatcher
      matcher = CategoryMatcher.new
      canonical_match = matcher.find_or_create(name: extra.name, category_type: extra.category_type)

      migration_plan << {
        extra: extra,
        canonical: canonical_match,
        repo_count: repo_count,
        comparison_count: comparison_count
      }
    end

    if migration_plan.any?
      puts "\nCategories with associations to migrate:"
      migration_plan.each do |plan|
        puts "  • #{plan[:extra].name} (#{plan[:extra].category_type}) → #{plan[:canonical].name}"
        puts "    - #{plan[:repo_count]} repository associations"
        puts "    - #{plan[:comparison_count]} comparison associations"
      end
    end

    # Categories with no associations (will be left alone)
    orphans = extra_categories - migration_plan.map { |p| p[:extra] }
    if orphans.any?
      puts "\nCategories with no associations (will be left alone):"
      orphans.each { |cat| puts "  • #{cat.name} (#{cat.category_type})" }
      puts "\n  💡 These can be manually deleted later if needed"
    end

    puts "\n" + "-" * 100

    # Confirm (unless SKIP_CONFIRM=1)
    unless ENV["SKIP_CONFIRM"] == "1"
      print "\nProceed with migration? (y/n): "
      response = STDIN.gets&.chomp&.downcase
      unless response == "y"
        puts "\nCancelled."
        exit
      end
    end

    # Execute migration
    puts "\n🔄 Migrating associations..."

    categories_to_delete = []
    migration_plan.each do |plan|
      extra = plan[:extra]
      canonical = plan[:canonical]

      # Skip if it's the same category (already canonical)
      if extra.id == canonical.id
        puts "  ⏭️  Skipping #{extra.name} (already canonical)"
        next
      end

      # Migrate repository_categories
      RepositoryCategory.where(category_id: extra.id).update_all(category_id: canonical.id)

      # Migrate comparison_categories
      ComparisonCategory.where(category_id: extra.id).update_all(category_id: canonical.id)

      puts "  ✅ Migrated #{extra.name} → #{canonical.name}"
      categories_to_delete << extra
    end

    # Delete only categories that had associations migrated
    if categories_to_delete.any?
      puts "\n🗑️  Deleting #{categories_to_delete.count} migrated categories..."
      deleted_count = Category.where(id: categories_to_delete.map(&:id)).destroy_all.count
      puts "  ✅ Deleted #{deleted_count} categories"
    end

    # Summary
    puts "\n" + "=" * 100
    puts "✅ MIGRATION COMPLETE"
    puts "=" * 100
    puts "\nFinal count: #{Category.count} categories"
    puts "Repository associations: #{RepositoryCategory.count}"
    puts "Comparison associations: #{ComparisonCategory.count}"
    puts "\n💡 Next step: bin/rails categories:generate_embeddings"
    puts "=" * 100
  end
end
