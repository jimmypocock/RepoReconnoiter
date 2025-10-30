# Service wrapper for GitHub API using Octokit
# Handles authentication, rate limiting, and common API operations
class GithubApiService
  attr_reader :client

  def initialize
    @client = Octokit::Client.new(
      access_token: Rails.application.credentials.github&.personal_access_token
    )
  end

  # Search for trending repositories (recently created, sorted by stars)
  # @param days_ago [Integer] How many days back to search (default: 7)
  # @param language [String, nil] Filter by programming language
  # @param min_stars [Integer] Minimum number of stars (default: 10)
  # @param per_page [Integer] Results per page (max 100)
  # @return [Sawyer::Resource] Search results with 'items' array
  def search_trending_repos(days_ago: 7, language: nil, min_stars: 10, per_page: 30)
    date = days_ago.days.ago.strftime("%Y-%m-%d")

    query_parts = [
      "created:>#{date}",
      "stars:>=#{min_stars}"
    ]
    query_parts << "language:#{language}" if language.present?

    query = query_parts.join(" ")

    client.search_repositories(query, {
      sort: "stars",
      order: "desc",
      per_page: per_page
    })
  end

  # Get detailed information about a specific repository
  # @param full_name [String] Repository full name (e.g., "rails/rails")
  # @return [Sawyer::Resource] Repository details
  def get_repository(full_name)
    client.repository(full_name)
  end

  # Get README content for a repository
  # @param full_name [String] Repository full name
  # @return [Sawyer::Resource] README metadata and content
  def get_readme(full_name)
    client.readme(full_name, accept: "application/vnd.github.v3.html")
  end

  # Get recent issues for a repository
  # @param full_name [String] Repository full name
  # @param state [String] Issue state: 'open', 'closed', 'all' (default: 'all')
  # @param per_page [Integer] Results per page (max 100)
  # @return [Array<Sawyer::Resource>] Array of issues
  def get_issues(full_name, state: "all", per_page: 30)
    client.issues(full_name, {
      state: state,
      sort: "created",
      direction: "desc",
      per_page: per_page
    })
  end

  # Get current rate limit status
  # @return [Sawyer::Resource] Rate limit information
  def rate_limit_status
    client.rate_limit
  end

  # Check if we're authenticated
  # @return [Boolean]
  def authenticated?
    client.access_token.present?
  end

  # Get current user (only works if authenticated)
  # @return [Sawyer::Resource, nil] User info or nil if not authenticated
  def current_user
    return nil unless authenticated?

    @current_user ||= client.user
  end
end
