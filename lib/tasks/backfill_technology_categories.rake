namespace :categories do
  desc "Backfill technology categories for existing repositories based on GitHub language"
  task backfill_technology: :environment do
    puts "🔄 Backfilling technology categories for existing repositories..."

    repos = Repository.where.not(language: nil)
    total = repos.count
    processed = 0
    added = 0
    skipped = 0

    repos.find_each do |repo|
      processed += 1
      language_slug = repo.language.parameterize

      # Find or create the category
      category = Category.find_or_create_by!(slug: language_slug, category_type: "technology") do |c|
        c.name = repo.language
        c.description = "#{repo.language} programming language and tools"
      end

      # Only create association if it doesn't already exist
      if repo.repository_categories.exists?(category_id: category.id)
        skipped += 1
        print "."
      else
        repo.repository_categories.create!(
          category_id: category.id,
          confidence_score: 1.0,
          assigned_by: "github_language"
        )
        added += 1
        print "+"
      end

      # Progress indicator every 50 repos
      puts " [#{processed}/#{total}]" if processed % 50 == 0
    end

    puts "\n\n✅ Backfill complete!"
    puts "   Total repositories: #{total}"
    puts "   Categories added: #{added}"
    puts "   Already assigned: #{skipped}"
    puts "   Unique technology categories: #{Category.technology.count}"
  end
end
