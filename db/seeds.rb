# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Clear existing categories (only in development)
if Rails.env.development?
  puts "Clearing existing categories..."
  Category.destroy_all
end

# Problem Domain Categories
puts "\n📋 Creating Problem Domain categories..."

problem_domains = [
  {
    name: "Authentication & Identity",
    description: "User authentication, authorization, identity management, OAuth, SSO, and access control systems"
  },
  {
    name: "Data Sync & Replication",
    description: "Database synchronization, real-time data replication, and distributed data consistency"
  },
  {
    name: "Rate Limiting & Throttling",
    description: "API rate limiting, request throttling, and traffic control mechanisms"
  },
  {
    name: "Background Job Processing",
    description: "Asynchronous job queues, background workers, and task scheduling systems"
  },
  {
    name: "Real-time Communication",
    description: "WebSockets, server-sent events, real-time messaging, and live updates"
  },
  {
    name: "API Client Generation",
    description: "Tools for generating API clients, SDKs, and type-safe API interfaces"
  },
  {
    name: "Testing & Mocking",
    description: "Testing frameworks, mocking libraries, fixtures, and test data generation"
  },
  {
    name: "Database Tools",
    description: "Database migrations, ORMs, query builders, and database management utilities"
  },
  {
    name: "Caching & Performance",
    description: "Caching layers, performance optimization, and response time improvements"
  },
  {
    name: "Monitoring & Observability",
    description: "Application monitoring, logging, tracing, metrics, and observability platforms"
  },
  {
    name: "Security & Encryption",
    description: "Encryption libraries, security tools, vulnerability scanning, and secure communication"
  },
  {
    name: "File Processing",
    description: "File uploads, image processing, PDF generation, and document handling"
  },
  {
    name: "Email & Notifications",
    description: "Email sending, SMS, push notifications, and communication services"
  },
  {
    name: "Payment Processing",
    description: "Payment gateways, billing systems, subscription management, and financial transactions"
  },
  {
    name: "Search & Indexing",
    description: "Full-text search, search engines, indexing systems, and query optimization"
  }
]

problem_domains.each do |attrs|
  category = Category.find_or_create_by!(
    name: attrs[:name],
    category_type: "problem_domain"
  )
  category.update!(description: attrs[:description])
  puts "  ✓ #{category.name}"
end

# Architecture Pattern Categories
puts "\n🏗️  Creating Architecture Pattern categories..."

architecture_patterns = [
  {
    name: "Microservices Tooling",
    description: "Service mesh, API gateways, service discovery, and microservices infrastructure"
  },
  {
    name: "Event-Driven Architecture",
    description: "Event sourcing, CQRS, message queues, pub/sub systems, and event streaming"
  },
  {
    name: "Serverless-Friendly",
    description: "Tools and libraries optimized for serverless environments like AWS Lambda, Vercel, Cloudflare Workers"
  },
  {
    name: "Monolith Utilities",
    description: "Tools for building and maintaining monolithic applications with modular architecture"
  },
  {
    name: "API-First Design",
    description: "REST APIs, GraphQL, API documentation, and API design tools"
  },
  {
    name: "CLI & Developer Tools",
    description: "Command-line interfaces, developer productivity tools, and automation scripts"
  },
  {
    name: "Frontend Frameworks",
    description: "UI libraries, component systems, and frontend application frameworks"
  },
  {
    name: "State Management",
    description: "Application state management, stores, and reactive data flow"
  }
]

architecture_patterns.each do |attrs|
  category = Category.find_or_create_by!(
    name: attrs[:name],
    category_type: "architecture_pattern"
  )
  category.update!(description: attrs[:description])
  puts "  ✓ #{category.name}"
end

# Maturity Level Categories
puts "\n📊 Creating Maturity Level categories..."

maturity_levels = [
  {
    name: "Experimental",
    description: "Recently created projects (< 6 months old, < 100 stars). Early stage, APIs may change frequently."
  },
  {
    name: "Active Development",
    description: "Frequent commits, responsive maintainers, actively evolving with community engagement."
  },
  {
    name: "Production Ready",
    description: "Stable API, good documentation, active maintenance, suitable for production use."
  },
  {
    name: "Enterprise Grade",
    description: "Security audits, commercial support available, used by major companies, battle-tested at scale."
  },
  {
    name: "Abandoned",
    description: "No commits in 6+ months, unresponsive maintainers, consider alternatives."
  }
]

maturity_levels.each do |attrs|
  category = Category.find_or_create_by!(
    name: attrs[:name],
    category_type: "maturity"
  )
  category.update!(description: attrs[:description])
  puts "  ✓ #{category.name}"
end

# Summary
puts "\n✅ Seeding complete!"
puts "   Problem Domains: #{Category.problem_domains.count}"
puts "   Architecture Patterns: #{Category.architecture_patterns.count}"
puts "   Maturity Levels: #{Category.maturity_levels.count}"
puts "   Total Categories: #{Category.count}"
