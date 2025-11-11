namespace :category do
  desc "Dump current categories to seeds file"
  task dump_seeds: :environment do
    puts "\n" + "=" * 100
    puts "DUMP CATEGORIES TO SEEDS"
    puts "=" * 100

    total_count = Category.count
    categories = Category.order(:category_type, :name).select(:name, :category_type, :description, :slug)

    # Group by type
    by_type = categories.group_by(&:category_type)

    seeds_content = <<~RUBY
      # frozen_string_literal: true

      # Canonical category definitions
      # Generated: #{Time.current.strftime("%Y-%m-%d %H:%M:%S")}
      # Total categories: #{total_count}
      # NOTE: Creates exact categories (no fuzzy matching) to avoid conflicts

      puts "Seeding categories..."

    RUBY

    # Add each type (no maturity - that's a repo attribute now)
    [ "technology", "problem_domain", "architecture_pattern" ].each do |type|
      next unless by_type[type]

      seeds_content << "\n# #{type.titleize} (#{by_type[type].count} categories)\n"

      by_type[type].each do |cat|
        # Escape single quotes in name and description
        safe_name = cat.name.gsub("'", "\\\\'")
        safe_desc = cat.description.gsub("'", "\\\\'")

        # Find or initialize by slug AND type to avoid cross-type conflicts
        seeds_content << "category = Category.find_or_initialize_by(slug: '#{cat.slug}', category_type: '#{type}')\n"
        seeds_content << "category.name = '#{safe_name}'\n"
        seeds_content << "category.description = '#{safe_desc}'\n"
        seeds_content << "category.save!\n"
      end
    end

    seeds_content << "\nputs \"✅ Categories seeded successfully!\"\n"

    # Write to file
    seeds_file = Rails.root.join("db", "seeds", "categories.rb")
    FileUtils.mkdir_p(File.dirname(seeds_file))
    File.write(seeds_file, seeds_content)

    puts "\n✅ Dumped #{total_count} categories to: #{seeds_file}"
    puts "\nBreakdown by type:"
    by_type.each do |type, cats|
      puts "  #{type}: #{cats.count}"
    end

    puts "\n💡 To load seeds: bin/rails db:seed"
    puts "\n" + "=" * 100
  end
end
