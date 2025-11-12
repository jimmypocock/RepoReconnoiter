# API Key Management Tasks
#
# Usage:
#   bin/rails api_keys:generate NAME="Next.js Production"
#   bin/rails api_keys:generate NAME="Next.js Production" EMAIL="user@example.com"
#   bin/rails api_keys:list
#   bin/rails api_keys:revoke ID=123
#   bin/rails api_keys:stats

namespace :api_keys do
  desc "Generate a new API key"
  task generate: :environment do
    name = ENV["NAME"] || "Unnamed API Key"
    email = ENV["EMAIL"]

    # Find user if email provided
    user = nil
    if email.present?
      user = User.find_by(email: email)
      unless user
        puts "❌ User not found with email: #{email}"
        exit 1
      end
    end

    # Generate the key
    result = ApiKey.generate(name: name, user: user)
    api_key = result[:api_key]
    raw_key = result[:raw_key]

    puts "✅ API Key Generated Successfully!"
    puts ""
    puts "Name:       #{api_key.name}"
    puts "ID:         #{api_key.id}"
    puts "User:       #{user&.email || 'System (no user)'}"
    puts "Created:    #{api_key.created_at}"
    puts ""
    puts "🔑 API Key: #{raw_key}"
    puts ""
    puts "⚠️  IMPORTANT: Save this key NOW! It will not be shown again."
    puts ""
    puts "To use in Next.js (Vercel env vars):"
    puts "  API_KEY=#{raw_key}"
    puts ""
    puts "To use in curl:"
    puts "  curl -H \"Authorization: Bearer #{raw_key}\" https://api.reporeconnoiter.com/v1/comparisons"
  end

  desc "List all API keys"
  task list: :environment do
    keys = ApiKey.includes(:user).order(created_at: :desc)

    if keys.empty?
      puts "No API keys found."
      exit 0
    end

    puts "API Keys:"
    puts ""
    printf "%-5s %-30s %-20s %-10s %-15s %-20s\n",
           "ID", "Name", "User", "Requests", "Status", "Last Used"
    puts "-" * 100

    keys.each do |key|
      status = key.active? ? "Active" : "Revoked"
      user_email = key.user&.email || "System"
      last_used = key.last_used_at ? key.last_used_at : "Never"

      printf "%-5d %-30s %-20s %-10d %-15s %-20s\n",
             key.id,
             key.name.truncate(28),
             user_email.truncate(18),
             key.request_count,
             status,
             last_used
    end

    puts ""
    puts "Total: #{keys.count} keys"
    puts "Active: #{keys.active.count}"
    puts "Revoked: #{keys.revoked.count}"
  end

  desc "Revoke an API key by ID"
  task revoke: :environment do
    id = ENV["ID"]

    unless id
      puts "❌ Error: ID required"
      puts "Usage: bin/rails api_keys:revoke ID=123"
      exit 1
    end

    api_key = ApiKey.find_by(id: id)

    unless api_key
      puts "❌ API Key not found with ID: #{id}"
      exit 1
    end

    if api_key.revoked_at?
      puts "⚠️  API Key is already revoked"
      puts ""
      puts "Name:     #{api_key.name}"
      puts "Revoked:  #{api_key.revoked_at}"
      exit 0
    end

    api_key.revoke!

    puts "✅ API Key Revoked Successfully!"
    puts ""
    puts "Name:      #{api_key.name}"
    puts "ID:        #{api_key.id}"
    puts "User:      #{api_key.user&.email || 'System'}"
    puts "Requests:  #{api_key.request_count}"
    puts "Revoked:   #{api_key.revoked_at}"
  end

  desc "Show API key statistics"
  task stats: :environment do
    total = ApiKey.count
    active = ApiKey.active.count
    revoked = ApiKey.revoked.count
    total_requests = ApiKey.sum(:request_count)

    most_used = ApiKey.active.order(request_count: :desc).limit(5)

    puts "API Key Statistics"
    puts "=" * 50
    puts ""
    puts "Total Keys:      #{total}"
    puts "Active:          #{active}"
    puts "Revoked:         #{revoked}"
    puts "Total Requests:  #{total_requests.to_s(:delimited)}"
    puts ""

    if most_used.any?
      puts "Most Used Keys (Top 5):"
      puts ""
      printf "%-5s %-30s %-10s %-20s\n",
             "ID", "Name", "Requests", "Last Used"
      puts "-" * 70

      most_used.each do |key|
        last_used = key.last_used_at ? key.last_used_at : "Never"
        printf "%-5d %-30s %-10d %-20s\n",
               key.id,
               key.name.truncate(28),
               key.request_count,
               last_used
      end
    end
  end

  desc "Clean up old revoked keys (older than 90 days)"
  task cleanup: :environment do
    cutoff = 90.days.ago
    old_keys = ApiKey.where("revoked_at < ?", cutoff)
    count = old_keys.count

    if count.zero?
      puts "No old revoked keys to clean up."
      exit 0
    end

    puts "Found #{count} revoked keys older than 90 days."
    print "Delete them? (y/N): "
    response = STDIN.gets.chomp

    unless response.downcase == "y"
      puts "Aborted."
      exit 0
    end

    old_keys.destroy_all
    puts "✅ Deleted #{count} old API keys."
  end
end
