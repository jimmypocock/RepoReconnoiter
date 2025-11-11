# GitHub API wrapper using Octokit
# Handles authentication, rate limiting, and common API operations
class Github
  def initialize
    @client = Octokit::Client.new(
      access_token: Rails.application.credentials.github&.personal_access_token
    )
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Fetch issues for a repository
  # @param full_name [String] Repository full name (e.g., "rails/rails")
  # @param options [Hash] Any valid Octokit issues options (state, per_page, etc.)
  # @return [Array<Sawyer::Resource>] Array of issues
  def fetch_issues(full_name, **options)
    client.issues(full_name, **options)
  rescue Octokit::NotFound, Octokit::Error => e
    Rails.logger.error "Failed to fetch issues for #{full_name}: #{e.message}"
    []
  end

  # Fetch README content for a repository
  # @param full_name [String] Repository full name (e.g., "rails/rails")
  # @return [String, nil] README content or nil if not found
  def fetch_readme(full_name)
    readme = client.readme(full_name, accept: "application/vnd.github.raw")
    readme
  rescue Octokit::NotFound
    nil
  end

  # Generic search for repositories using any query string
  # @param query [String] GitHub search query (e.g., "react state language:javascript stars:>500")
  # @param options [Hash] Any valid Octokit search options (per_page, sort, order, etc.)
  # @return [Sawyer::Resource] Search results with 'items' array
  def search(query, **options)
    client.search_repositories(query, **options)
  end

  # Search for trending repositories (recently created, sorted by stars)
  # @param days_ago [Integer] How many days back to search (default: 7)
  # @param language [String, nil] Filter by programming language
  # @param min_stars [Integer] Minimum number of stars (default: 10)
  # @param per_page [Integer] Results per page (max 100)
  # @return [Sawyer::Resource] Search results with 'items' array
  def search_trending(days_ago: 7, language: nil, min_stars: 10, per_page: 30)
    date = days_ago.days.ago.strftime("%Y-%m-%d")

    query_parts = [
      "created:>#{date}",
      "stars:>=#{min_stars}"
    ]
    query_parts << "language:#{language}" if language.present?

    query = query_parts.join(" ")

    search(query, sort: "stars", order: "desc", per_page: per_page)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    delegate :search, :search_trending, to: :new
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  attr_reader :client
end
