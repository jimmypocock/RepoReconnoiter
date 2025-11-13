# User Whitelist Management Tasks
#
# Manage the invite-only whitelist for authentication.
# Users must be whitelisted to sign in via GitHub OAuth.
#
# Examples:
#   bin/rails whitelist:add                                          # Interactive: prompts for GitHub username/ID
#   bin/rails whitelist:add[12345678,johndoe,john@example.com]      # Add by GitHub ID and username
#   bin/rails whitelist:list                                         # List all whitelisted users
#   bin/rails whitelist:remove[johndoe]                              # Remove user by GitHub username

namespace :whitelist do
  desc "Add a user to the whitelist (interactive or with arguments)"
  task :add, [ :github_id, :github_username, :email, :notes ] => :environment do |_t, args|
    if args.github_id.present?
      # Use provided arguments
      github_id = args.github_id.to_i
      github_username = args.github_username
      email = args.email
      notes = args.notes || "Added via rake task"
    else
      # Interactive prompts
      puts "\n🔐 Add User to Whitelist\n\n"
      puts "You can provide either a GitHub username OR GitHub ID\n\n"

      print "GitHub username or ID: "
      input = $stdin.gets.strip

      if input.blank?
        puts "❌ GitHub username or ID is required"
        exit 1
      end

      # Determine if input is username or ID
      if input.match?(/^\d+$/)
        # Input is a GitHub ID
        github_id_input = input.to_i
        print "Fetching GitHub username for ID #{github_id_input}... "

        begin
          require "net/http"
          require "json"

          uri = URI("https://api.github.com/user/#{github_id_input}")
          response = Net::HTTP.get(uri)
          data = JSON.parse(response)

          if data["login"]
            github_id = github_id_input
            github_username = data["login"]
            fetched_email = data["email"]
            puts "✓ Found @#{github_username}"
            puts "   Public email: #{fetched_email || '(none)'}" if fetched_email.present?
          else
            puts "❌ User not found"
            exit 1
          end
        rescue StandardError => e
          puts "❌ Error fetching GitHub data: #{e.message}"
          exit 1
        end
      else
        # Input is a GitHub username
        github_username_input = input
        print "Fetching GitHub data for @#{github_username_input}... "

        begin
          require "net/http"
          require "json"

          uri = URI("https://api.github.com/users/#{github_username_input}")
          response = Net::HTTP.get(uri)
          data = JSON.parse(response)

          if data["id"]
            github_id = data["id"]
            github_username = data["login"] # Use canonical username from API
            fetched_email = data["email"]
            puts "✓ Found (ID: #{github_id})"
            puts "   Public email: #{fetched_email || '(none)'}" if fetched_email.present?
          else
            puts "❌ User not found"
            exit 1
          end
        rescue StandardError => e
          puts "❌ Error fetching GitHub data: #{e.message}"
          exit 1
        end
      end

      # Prompt for email if not already fetched
      if fetched_email.present?
        print "Use fetched email (#{fetched_email})? (Y/n): "
        use_fetched = $stdin.gets.strip.downcase
        email = (use_fetched == "n") ? nil : fetched_email

        if use_fetched == "n"
          print "Enter different email (or press Enter to skip): "
          email = $stdin.gets.strip
          email = nil if email.blank?
        end
      else
        print "Email (optional, press Enter to skip): "
        email = $stdin.gets.strip
        email = nil if email.blank?
      end

      print "Notes (optional, press Enter to skip): "
      notes = $stdin.gets.strip
      notes = "Added via rake task" if notes.blank?
    end

    # Validate required fields
    if github_id.zero? || github_username.blank?
      puts "❌ GitHub ID and username are required"
      exit 1
    end

    # Check if already whitelisted
    if WhitelistedUser.exists?(github_id: github_id)
      puts "⚠️  User @#{github_username} (ID: #{github_id}) is already whitelisted"
      exit 0
    end

    # Create whitelist entry
    begin
      WhitelistedUser.create!(
        github_id: github_id,
        github_username: github_username,
        email: email,
        added_by: ENV["USER"] || "unknown",
        notes: notes
      )

      puts "\n✅ Successfully whitelisted @#{github_username}"
      puts "   GitHub ID: #{github_id}"
      puts "   Email: #{email || '(none)'}"
      puts "   Notes: #{notes}"

      # Show environment-appropriate URL
      app_url = Rails.env.production? ? "https://reporeconnoiter.com" : "http://localhost:3001"
      puts "\nThey can now sign in at: #{app_url}"
    rescue StandardError => e
      puts "❌ Error creating whitelist entry: #{e.message}"
      exit 1
    end
  end

  desc "List all whitelisted users"
  task list: :environment do
    users = WhitelistedUser.order(created_at: :desc)

    if users.empty?
      puts "No whitelisted users found"
      exit 0
    end

    puts "\n📋 Whitelisted Users (#{users.count})\n\n"

    users.each do |user|
      puts "  @#{user.github_username} (ID: #{user.github_id})"
      puts "    Email: #{user.email || '(none)'}"
      puts "    Added by: #{user.added_by || 'unknown'}"
      puts "    Added at: #{user.created_at.strftime('%Y-%m-%d %H:%M')}"
      puts "    Notes: #{user.notes}" if user.notes.present?
      puts ""
    end
  end

  desc "Remove a user from the whitelist"
  task :remove, [ :github_username ] => :environment do |_t, args|
    if args.github_username.blank?
      print "GitHub username to remove: "
      github_username = $stdin.gets.strip
    else
      github_username = args.github_username
    end

    user = WhitelistedUser.find_by(github_username: github_username)

    if user.nil?
      puts "❌ User @#{github_username} not found in whitelist"
      exit 1
    end

    print "Are you sure you want to remove @#{github_username} from the whitelist? (y/N): "
    confirmation = $stdin.gets.strip.downcase

    if confirmation == "y"
      user.destroy!
      puts "✅ Removed @#{github_username} from whitelist"
    else
      puts "Cancelled"
    end
  end
end
