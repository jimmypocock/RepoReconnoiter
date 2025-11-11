class RepositorySyncer
  attr_reader :github

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def initialize
    @github = Github.new
  end

  # Syncs trending repositories from GitHub
  # Options: days_ago, min_stars, per_page
  # Returns: { synced:, created:, updated: }
  def sync_trending(days_ago: 7, min_stars: 50, per_page: 10)
    results = github.search_trending(
      days_ago: days_ago,
      min_stars: min_stars,
      per_page: per_page
    )

    sync_repositories(results.items)
  end

  # Syncs a collection of GitHub API repository items
  # Returns: { synced:, created:, updated:, repositories: [] }
  def sync_repositories(items, created: 0, synced: 0, updated: 0)
    repositories = []

    items.each do |item|
      repo = Repository.from_github_api(item.to_attrs)

      if repo.new_record?
        repo.save!
        created += 1
      else
        repo.save!
        updated += 1
      end

      synced += 1
      repositories << repo
    rescue => e
      Rails.logger.error "❌ Error syncing repo #{item.full_name}: #{e.message}"
    end

    { created:, repositories:, synced:, updated: }
  end

  class << self
    delegate :sync_trending, to: :new
  end
end
