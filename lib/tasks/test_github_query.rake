namespace :query do
  desc "Test a GitHub search query to see what results it returns"
  task :test_github, [:query] => :environment do |t, args|
    query = args[:query] || "rails background job retry language:ruby stars:>100"

    puts "\n🔍 Testing GitHub Search Query:"
    puts "=" * 80
    puts query
    puts "=" * 80

    github = GithubApiService.new

    begin
      results = github.client.search_repositories(query, per_page: 10)

      puts "\n✅ Found #{results.total_count} total repositories"
      puts "\nTop 10 Results:\n"

      results.items.each_with_index do |repo, index|
        puts "#{index + 1}. #{repo.full_name} (⭐ #{repo.stargazers_count})"
        puts "   #{repo.description&.slice(0, 100)}..."
        puts ""
      end

      puts "\n💡 Are these the repos you'd expect for this query?"

    rescue => e
      puts "\n❌ Error: #{e.message}"
    end

    puts "\n"
  end
end
