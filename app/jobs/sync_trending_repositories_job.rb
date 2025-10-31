class SyncTrendingRepositoriesJob < ApplicationJob
  queue_as :default

  def perform
    github = Github.new

    Rails.logger.info "🔄 Starting sync of trending repositories..."

    # Start small - just fetch 10 repos from the last 7 days
    results = github.search_trending(
      days_ago: 7,
      min_stars: 50,
      per_page: 10
    )

    repos_synced = 0
    repos_updated = 0
    repos_created = 0

    results.items.each do |item|
      repo_data = item.to_attrs
      repo = Repository.from_github_api(repo_data)

      if repo.new_record?
        repo.save!
        repos_created += 1
      else
        repo.save!
        repos_updated += 1
      end

      repos_synced += 1
    rescue => e
      Rails.logger.error "❌ Error syncing repo #{repo_data[:full_name]}: #{e.message}"
    end

    Rails.logger.info "✅ Sync complete: #{repos_synced} repos (#{repos_created} new, #{repos_updated} updated)"

    {
      synced: repos_synced,
      created: repos_created,
      updated: repos_updated
    }
  end
end
