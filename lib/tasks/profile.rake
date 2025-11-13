# User Profile Management Tasks
#
# Manage user accounts and profile data.
#
# Examples:
#   bin/rails profile:delete[johndoe]          # Delete user by GitHub username (soft delete)
#   bin/rails profile:delete[12345678]         # Delete user by GitHub ID (soft delete)
#   bin/rails profile:info[johndoe]            # Show user profile information

namespace :profile do
  desc "Delete a user account (soft delete with deleted_at)"
  task :delete, [ :identifier ] => :environment do |_t, args|
    if args.identifier.blank?
      puts "\n🗑️  Delete User Account\n\n"
      print "GitHub username or ID: "
      identifier = $stdin.gets.strip
    else
      identifier = args.identifier
    end

    if identifier.blank?
      puts "❌ GitHub username or ID is required"
      exit 1
    end

    # Find user by GitHub ID or username
    user = if identifier.match?(/^\d+$/)
             User.find_by(github_id: identifier.to_i)
           else
             User.find_by(github_username: identifier)
           end

    if user.nil?
      puts "❌ User not found: #{identifier}"
      exit 1
    end

    if user.deleted_at.present?
      puts "⚠️  User @#{user.github_username} is already deleted (#{user.deleted_at.strftime('%Y-%m-%d')})"
      exit 0
    end

    # Show user info before deletion
    puts "\n📋 User to delete:"
    puts "   Username: @#{user.github_username}"
    puts "   GitHub ID: #{user.github_id}"
    puts "   Email: #{user.email}"
    puts "   Comparisons created: #{user.comparisons.count}"
    puts "   Analyses created: #{user.analyses.count}"
    puts "   Account created: #{user.created_at.strftime('%Y-%m-%d')}"
    puts ""

    print "Are you sure you want to delete this account? (y/N): "
    confirmation = $stdin.gets.strip.downcase

    if confirmation == "y"
      # Soft delete: set deleted_at timestamp
      user.update!(deleted_at: Time.current)

      puts "✅ User @#{user.github_username} has been deleted (soft delete)"
      puts "   Data has been preserved for referential integrity"
      puts "   User can no longer sign in"
    else
      puts "Cancelled"
    end
  end

  desc "Show user profile information"
  task :info, [ :identifier ] => :environment do |_t, args|
    if args.identifier.blank?
      puts "\n📋 User Profile Information\n\n"
      print "GitHub username or ID: "
      identifier = $stdin.gets.strip
    else
      identifier = args.identifier
    end

    if identifier.blank?
      puts "❌ GitHub username or ID is required"
      exit 1
    end

    # Find user by GitHub ID or username
    user = if identifier.match?(/^\d+$/)
             User.find_by(github_id: identifier.to_i)
           else
             User.find_by(github_username: identifier)
           end

    if user.nil?
      puts "❌ User not found: #{identifier}"
      exit 1
    end

    # Display user information
    puts "\n📋 User Profile\n\n"
    puts "  Username: @#{user.github_username}"
    puts "  GitHub ID: #{user.github_id}"
    puts "  Email: #{user.email}"
    puts "  Admin: #{user.admin? ? 'Yes' : 'No'}"
    puts "  Status: #{user.deleted_at.present? ? "Deleted (#{user.deleted_at.strftime('%Y-%m-%d')})" : 'Active'}"
    puts ""

    puts "  Account Activity:"
    puts "    Created: #{user.created_at.strftime('%Y-%m-%d %H:%M')}"
    puts "    Last updated: #{user.updated_at.strftime('%Y-%m-%d %H:%M')}"
    puts ""

    puts "  Usage:"
    puts "    Comparisons created: #{user.comparisons.count}"
    puts "    Analyses created: #{user.analyses.count}"
    puts "    Total AI cost: $#{user.total_ai_cost_spent.round(2)}"
    puts ""

    # Show rate limit info
    remaining_comparisons = user.remaining_comparisons_today
    remaining_analyses = user.remaining_analyses_today

    puts "  Rate Limits (today):"
    puts "    Comparisons remaining: #{remaining_comparisons}"
    puts "    Analyses remaining: #{remaining_analyses}"
    puts ""
  end

  desc "Restore a soft-deleted user account"
  task :restore, [ :identifier ] => :environment do |_t, args|
    if args.identifier.blank?
      puts "\n♻️  Restore User Account\n\n"
      print "GitHub username or ID: "
      identifier = $stdin.gets.strip
    else
      identifier = args.identifier
    end

    if identifier.blank?
      puts "❌ GitHub username or ID is required"
      exit 1
    end

    # Find user by GitHub ID or username (including deleted)
    user = if identifier.match?(/^\d+$/)
             User.unscoped.find_by(github_id: identifier.to_i)
           else
             User.unscoped.find_by(github_username: identifier)
           end

    if user.nil?
      puts "❌ User not found: #{identifier}"
      exit 1
    end

    if user.deleted_at.nil?
      puts "⚠️  User @#{user.github_username} is not deleted"
      exit 0
    end

    puts "\n📋 User to restore:"
    puts "   Username: @#{user.github_username}"
    puts "   Deleted at: #{user.deleted_at.strftime('%Y-%m-%d %H:%M')}"
    puts ""

    print "Restore this account? (y/N): "
    confirmation = $stdin.gets.strip.downcase

    if confirmation == "y"
      user.update!(deleted_at: nil)
      puts "✅ User @#{user.github_username} has been restored"
      puts "   User can now sign in again"
    else
      puts "Cancelled"
    end
  end
end
