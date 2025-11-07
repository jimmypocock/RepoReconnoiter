namespace :github do
  desc "Explore GitHub API and display available data"
  task explore: :environment do
    # Use Octokit client directly for exploration
    client = Octokit::Client.new(
      access_token: Rails.application.credentials.github&.personal_access_token
    )

    puts "\n" + "=" * 80
    puts "GitHub API Explorer"
    puts "=" * 80

    # Check authentication
    puts "\n📡 Authentication Status:"
    if client.access_token.present?
      user = client.user
      puts "✅ Authenticated as: #{user.login}"
      puts "   Name: #{user.name}"
      puts "   Email: #{user.email}"
    else
      puts "⚠️  Not authenticated (using public API access)"
    end

    # Check rate limits
    puts "\n📊 Rate Limit Status:"
    rate_limit = client.rate_limit

    puts "   Limit: #{rate_limit.limit} requests/hour"
    puts "   Remaining: #{rate_limit.remaining}"
    puts "   Resets at: #{rate_limit.resets_at}"
    puts "   Resets in: #{rate_limit.resets_in} seconds"

    # Search for trending repos
    puts "\n🔥 Trending Repositories (last 7 days, min 10 stars):"
    puts "-" * 80

    results = Github.search_trending(days_ago: 7, min_stars: 10, per_page: 5)

    puts "Total found: #{results.total_count}"
    puts "Showing: #{results.items.count} repositories\n\n"

    results.items.each_with_index do |repo, index|
      puts "#{index + 1}. #{repo.full_name}"
      puts "   ⭐ Stars: #{repo.stargazers_count}"
      puts "   🍴 Forks: #{repo.forks_count}"
      puts "   📝 Description: #{repo.description&.truncate(100)}"
      puts "   🏷️  Topics: #{repo.topics.join(', ')}" if repo.topics.any?
      puts "   💻 Language: #{repo.language}"
      puts "   📅 Created: #{repo.created_at}"
      puts "   🔗 URL: #{repo.html_url}"
      puts ""
    end

    # Show detailed field structure for first repo
    if results.items.any?
      puts "\n📋 Available Fields (first repository):"
      puts "-" * 80
      first_repo = results.items.first

      # Get all available fields
      fields = first_repo.to_attrs.keys.sort
      fields.each_slice(3) do |field_group|
        puts "   " + field_group.map { |f| f.to_s.ljust(25) }.join(" ")
      end

      puts "\n📖 Sample README fetch:"
      puts "-" * 80
      begin
        readme = client.readme(first_repo.full_name, accept: "application/vnd.github.v3.html")
        puts "✅ README fetched successfully"
        puts "   Length: #{readme.length} characters"
        puts "   Preview: #{readme[0..200]}..."
      rescue Octokit::NotFound
        puts "❌ No README found"
      rescue => e
        puts "❌ Error: #{e.message}"
      end

      puts "\n🐛 Sample Issues fetch:"
      puts "-" * 80
      begin
        issues = client.issues(first_repo.full_name, state: "all", sort: "created", direction: "desc", per_page: 3)
        puts "✅ Found #{issues.count} recent issues"
        issues.first(3).each do |issue|
          puts "   - ##{issue.number}: #{issue.title.truncate(60)}"
          puts "     State: #{issue.state} | Comments: #{issue.comments}"
        end
      rescue => e
        puts "❌ Error: #{e.message}"
      end
    end

    puts "\n" + "=" * 80
    puts "✅ Exploration complete!"
    puts "=" * 80
  end

  desc "Search trending repos with custom parameters"
  task :trending, [ :days, :language, :min_stars ] => :environment do |t, args|
    args.with_defaults(days: 7, language: nil, min_stars: 10)

    results = Github.search_trending(
      days_ago: args[:days].to_i,
      language: args[:language],
      min_stars: args[:min_stars].to_i,
      per_page: 10
    )

    puts "\n🔥 Trending Repositories:"
    puts "Query: Created in last #{args[:days]} days, #{args[:language] || 'any language'}, min #{args[:min_stars]} stars"
    puts "Total found: #{results.total_count}\n\n"

    results.items.each_with_index do |repo, index|
      puts "#{index + 1}. #{repo.full_name} (⭐ #{repo.stargazers_count})"
      puts "   #{repo.description&.truncate(80)}"
      puts "   #{repo.html_url}\n\n"
    end
  end

  desc "Search GitHub repositories with any query string"
  task :search, [ :query ] => :environment do |t, args|
    query = args[:query] || "language:ruby stars:>1000"

    puts "\n🔍 GitHub Repository Search"
    puts "=" * 80
    puts "Query: #{query}"
    puts "=" * 80

    begin
      results = Github.search(query, per_page: 10)

      puts "\n✅ Found #{results.total_count} total repositories"
      puts "\nTop 10 Results:\n"

      results.items.each_with_index do |repo, index|
        puts "#{index + 1}. #{repo.full_name} (⭐ #{repo.stargazers_count})"
        puts "   🔧 #{repo.language || 'N/A'}"
        puts "   #{repo.description&.slice(0, 100)}..."
        puts ""
      end

      puts "💡 Are these the repos you'd expect for this query?\n"

    rescue => e
      puts "\n❌ Error: #{e.message}"
    end

    puts ""
  end

  desc "Sync trending repositories to database (same as SyncTrendingRepositoriesJob)"
  task :sync, [ :days, :min_stars, :per_page ] => :environment do |t, args|
    args.with_defaults(days: 7, min_stars: 50, per_page: 10)

    puts "\n🔄 Syncing Trending Repositories to Database"
    puts "=" * 80
    puts "Parameters:"
    puts "   Days ago: #{args[:days]}"
    puts "   Min stars: #{args[:min_stars]}"
    puts "   Per page: #{args[:per_page]}"
    puts "=" * 80

    begin
      start_time = Time.current
      initial_count = Repository.count

      # Call the same service the job uses
      result = RepositorySyncer.sync_trending(
        days_ago: args[:days].to_i,
        min_stars: args[:min_stars].to_i,
        per_page: args[:per_page].to_i
      )

      duration = (Time.current - start_time).round(2)

      puts "\n✅ Sync Complete!"
      puts "   Synced: #{result[:synced]} repositories"
      puts "   Created: #{result[:created]} new repositories"
      puts "   Updated: #{result[:updated]} existing repositories"
      puts "   Database now has: #{Repository.count} total repositories (was #{initial_count})"
      puts "   Duration: #{duration}s"

      if result[:created] > 0
        puts "\n📋 Newly Created Repositories:"
        Repository.order(created_at: :desc).limit(result[:created]).each do |repo|
          puts "   • #{repo.full_name} (⭐ #{repo.stargazers_count})"
        end
      end

      puts "\n💡 Tip: Run again to update existing repos with latest stars/forks/activity"

    rescue => e
      puts "\n❌ Error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end

    puts ""
  end
end
