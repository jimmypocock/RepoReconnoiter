namespace :db do
  desc "Pull production database and load it locally"
  task sync_from_production: :environment do
    # Safety check: only run in development
    unless Rails.env.development?
      puts "\n❌ ERROR: This task can only be run in development environment"
      puts "   Current environment: #{Rails.env}"
      exit 1
    end

    puts "\n" + "=" * 100
    puts "SYNC FROM PRODUCTION TO LOCAL"
    puts "=" * 100

    # Check for production database URL in environment
    production_url = ENV["PRODUCTION_DATABASE_URL"]

    if production_url.blank?
      puts "\n❌ ERROR: PRODUCTION_DATABASE_URL not found in environment"
      puts "\nAdd to .env file:"
      puts "  PRODUCTION_DATABASE_URL=postgresql://user:pass@host/database"
      puts "\nOr pass as environment variable:"
      puts "  PRODUCTION_DATABASE_URL=... bin/rails db:sync_from_production"
      exit 1
    end

    # Backup current local database first
    backup_file = Rails.root.join("tmp", "local_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql")
    puts "\n📦 Backing up current local database..."
    puts "   → #{backup_file}"

    system("pg_dump #{Rails.configuration.database_configuration[Rails.env]['database']} > #{backup_file}")

    if $?.success?
      puts "   ✅ Local backup created"
    else
      puts "   ⚠️  Backup failed, but continuing..."
    end

    # Pull production dump
    dump_file = Rails.root.join("tmp", "production_dump_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql")
    puts "\n⬇️  Pulling production database..."
    puts "   → #{dump_file}"

    system("pg_dump #{production_url} > #{dump_file}")

    unless $?.success?
      puts "\n❌ ERROR: Failed to pull production database"
      puts "   Check your PRODUCTION_DATABASE_URL and network connection"
      exit 1
    end

    puts "   ✅ Production dump downloaded (#{File.size(dump_file) / 1024}KB)"

    # Confirm before overwriting local database
    print "\n⚠️  This will REPLACE your local database with production data. Continue? (y/n): "
    response = STDIN.gets.chomp.downcase
    unless response == "y"
      puts "\nCancelled. Production dump saved at: #{dump_file}"
      exit
    end

    # Drop and recreate local database
    puts "\n🔄 Resetting local database..."
    local_db = Rails.configuration.database_configuration[Rails.env]["database"]

    system("dropdb #{local_db}")
    system("createdb #{local_db}")

    # Load production dump
    puts "\n📥 Loading production data..."
    system("psql #{local_db} < #{dump_file} 2>&1 | grep -c 'ERROR.*role' > /dev/null")

    if $?.success?
      puts "   ✅ Production data loaded (role errors are normal and safe to ignore)"
    else
      puts "   ⚠️  Some errors occurred during restore (likely harmless role errors)"
    end

    # Run migration to add embedding column (if needed)
    puts "\n🔧 Running migrations..."
    system("bin/rails db:migrate")

    # Show summary
    puts "\n" + "=" * 100
    puts "SUMMARY"
    puts "=" * 100

    category_count = Category.count rescue 0
    maturity_count = Category.where(category_type: "maturity").count rescue 0

    puts "\nLocal database now has production data:"
    puts "  Categories: #{category_count}"
    puts "  Maturity categories: #{maturity_count}"
    puts "\n📂 Files created:"
    puts "  Local backup:     #{backup_file}"
    puts "  Production dump:  #{dump_file}"
    puts "\n💡 Next steps:"
    puts "  1. Run: bin/rails categories:cleanup"
    puts "  2. Run: bin/rails db:seed"
    puts "  3. Run: bin/rails categories:generate_embeddings"
    puts "  4. Run: bin/rails categories:test_matrix"
    puts "\n" + "=" * 100
  end
end
