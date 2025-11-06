class SyncTrendingRepositoriesJob < ApplicationJob
  queue_as :default

  def perform
    RepositorySyncer.sync_trending(days_ago: 7, min_stars: 50, per_page: 10)
  end
end
