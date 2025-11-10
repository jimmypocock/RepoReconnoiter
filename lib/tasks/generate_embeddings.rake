namespace :categories do
  desc "Generate embeddings for categories that don't have them"
  task generate_embeddings: :environment do
    puts "\n" + "=" * 100
    puts "GENERATE CATEGORY EMBEDDINGS"
    puts "=" * 100

    matcher = CategoryMatcher.new
    categories_without_embeddings = Category.where(embedding: nil)

    puts "\nCategories without embeddings: #{categories_without_embeddings.count}"

    if categories_without_embeddings.count.zero?
      puts "✅ All categories already have embeddings!"
      exit
    end

    print "\nGenerate embeddings for #{categories_without_embeddings.count} categories? (y/n): "
    response = STDIN.gets.chomp.downcase
    unless response == "y"
      puts "Cancelled."
      exit
    end

    puts "\n🔧 Generating embeddings..."
    progress = 0

    categories_without_embeddings.find_each do |category|
      embedding = matcher.send(:generate_embedding, category.name)
      category.update!(embedding: embedding)
      progress += 1
      print "\r  Progress: #{progress}/#{categories_without_embeddings.count}"
    end

    puts "\n\n✅ Generated #{progress} embeddings!"
    puts "\n" + "=" * 100
  end
end
