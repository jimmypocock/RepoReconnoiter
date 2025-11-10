# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Clear existing categories (only in development)
if Rails.env.development?
  puts "Clearing existing categories..."
  Category.destroy_all
end

# Load canonical categories from seeds/categories.rb
load Rails.root.join("db", "seeds", "categories.rb")

# Summary
puts "\n✅ Seeding complete!"
puts "   Problem Domains: #{Category.problem_domain.count}"
puts "   Architecture Patterns: #{Category.architecture_pattern.count}"
puts "   Technologies: #{Category.technology.count}"
puts "   Total Categories: #{Category.count}"
