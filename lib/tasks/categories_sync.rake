namespace :categories do
  desc "Sync categories from production (lightweight - categories only)"
  task sync_from_production: :environment do
    unless Rails.env.development?
      puts "\n❌ ERROR: This task can only be run in development environment"
      exit 1
    end

    puts "\n" + "=" * 100
    puts "SYNC CATEGORIES FROM PRODUCTION"
    puts "=" * 100

    production_url = ENV["PRODUCTION_DATABASE_URL"]

    if production_url.blank?
      puts "\n❌ ERROR: PRODUCTION_DATABASE_URL not found"
      puts "Add to .env: PRODUCTION_DATABASE_URL=postgresql://..."
      exit 1
    end

    # Export categories from production
    dump_file = Rails.root.join("tmp", "prod_categories_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql")
    puts "\n⬇️  Exporting categories from production..."

    # Export only categories table
    system("pg_dump #{production_url} -t categories -t category_matcher_aliases > #{dump_file}")

    unless $?.success?
      puts "\n❌ ERROR: Failed to export categories from production"
      exit 1
    end

    puts "   ✅ Exported (#{File.size(dump_file) / 1024}KB)"

    # Clear local categories
    print "\n⚠️  This will REPLACE local categories. Continue? (y/n): "
    response = STDIN.gets&.chomp&.downcase
    unless response == "y"
      puts "\nCancelled."
      exit
    end

    puts "\n🗑️  Clearing local categories..."
    Category.destroy_all

    # Import categories
    puts "\n📥 Importing categories from production..."
    local_db = Rails.configuration.database_configuration[Rails.env]["primary"]["database"]
    system("psql #{local_db} < #{dump_file} 2>&1 | grep -v 'ERROR.*role' > /dev/null")

    puts "   ✅ Imported"

    # Summary
    puts "\n" + "=" * 100
    puts "✅ SYNC COMPLETE"
    puts "=" * 100
    puts "\nLocal categories: #{Category.count}"
    puts "  Technology: #{Category.where(category_type: 'technology').count}"
    puts "  Problem Domain: #{Category.where(category_type: 'problem_domain').count}"
    puts "  Architecture: #{Category.where(category_type: 'architecture_pattern').count}"
    puts "\n💡 Next step: Generate embeddings if needed"
    puts "=" * 100
  end
end
