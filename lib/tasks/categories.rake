namespace :categories do
  desc "Backfill embeddings for all existing categories"
  task backfill_embeddings: :environment do
    require "openai"

    puts "\n" + "=" * 80
    puts "BACKFILLING CATEGORY EMBEDDINGS"
    puts "=" * 80

    # Find categories without embeddings
    categories_without_embeddings = Category.where(embedding: nil)
    total = categories_without_embeddings.count

    if total.zero?
      puts "\n✅ All categories already have embeddings!"
      next
    end

    puts "\nCategories needing embeddings: #{total}"
    puts "Estimated cost: $#{format('%.6f', (total * 4 / 1_000_000.0) * 0.02)}" # ~4 tokens per name

    print "\nProceed? (y/n): "
    response = STDIN.gets.chomp.downcase
    unless response == "y"
      puts "Cancelled."
      next
    end

    # Initialize OpenAI client
    client = OpenAI::Client.new(
      api_key: Rails.application.credentials.openai&.api_key
    )

    # Batch process categories (OpenAI allows up to 2048 inputs per request)
    batch_size = 100
    successful = 0
    failed = 0

    categories_without_embeddings.in_batches(of: batch_size) do |batch|
      names = batch.pluck(:name)

      puts "\nProcessing batch of #{names.count}..."

      begin
        # Fetch embeddings in batch
        response = client.embeddings.create(
          model: "text-embedding-3-small",
          input: names
        )

        # Update each category with its embedding
        batch.each_with_index do |category, idx|
          embedding = response[:data][idx][:embedding]
          category.update!(embedding: embedding)
          successful += 1
          print "."
        end

        puts " ✅"
      rescue => e
        puts " ❌"
        puts "Error: #{e.message}"
        failed += names.count
      end
    end

    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80
    puts "Successful: #{successful}"
    puts "Failed: #{failed}"
    puts "Total: #{total}"
    puts "\n✅ Backfill complete!"
  end

  desc "Find and merge duplicate categories using semantic similarity"
  task find_duplicates: :environment do
    puts "\n" + "=" * 80
    puts "FINDING DUPLICATE CATEGORIES"
    puts "=" * 80

    # Group by category type
    Category.distinct.pluck(:category_type).each do |category_type|
      puts "\n📁 #{category_type.titleize}"
      puts "-" * 80

      categories = Category.where(category_type: category_type).where.not(embedding: nil)
      matcher = CategoryMatcher.new

      duplicates_found = []

      categories.each do |cat1|
        categories.where("id > ?", cat1.id).each do |cat2|
          similarity = matcher.send(:cosine_similarity, cat1.embedding, cat2.embedding)

          if similarity >= CategoryMatcher::EMBEDDING_THRESHOLD
            duplicates_found << {
              cat1: cat1.name,
              cat2: cat2.name,
              similarity: similarity
            }
          end
        end
      end

      if duplicates_found.empty?
        puts "✅ No duplicates found"
      else
        duplicates_found.sort_by { |d| -d[:similarity] }.each do |dup|
          puts "  ⚠️  '#{dup[:cat1]}' ≈ '#{dup[:cat2]}' (#{format('%.2f', dup[:similarity])})"
        end
      end
    end

    puts "\n" + "=" * 80
  end

  desc "Show category statistics"
  task stats: :environment do
    puts "\n" + "=" * 80
    puts "CATEGORY STATISTICS"
    puts "=" * 80

    total = Category.count
    with_embeddings = Category.where.not(embedding: nil).count
    without_embeddings = total - with_embeddings

    puts "\nTotal categories: #{total}"
    puts "With embeddings: #{with_embeddings} (#{format('%.1f', (with_embeddings / total.to_f) * 100)}%)"
    puts "Without embeddings: #{without_embeddings}"

    puts "\nBy type:"
    Category.group(:category_type).count.each do |type, count|
      puts "  #{type.ljust(20)}: #{count}"
    end

    puts "\n" + "=" * 80
  end
end
