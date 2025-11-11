# ComparisonCreator - Orchestrates the comparison creation pipeline
#
# Coordinates UserQueryParser, RepositoryFetcher, and RepositoryComparer
# to create repository comparisons from user queries.
#
# Usage:
#   result = ComparisonCreator.call(query: "Rails background jobs")
#   result.record         # The Comparison record
#   result.newly_created  # Boolean - was this just created (vs retrieved from cache)?
#   result.similarity     # Float - cache similarity score (1.0 if new)
class ComparisonCreator
  #--------------------------------------
  # CUSTOM EXCEPTIONS
  #--------------------------------------

  class InvalidQueryError < StandardError; end
  class NoRepositoriesFoundError < StandardError; end

  attr_reader :query, :force_refresh, :user, :session_id, :broadcaster, :record, :newly_created, :similarity

  def initialize(query:, force_refresh: false, user: nil, session_id: nil)
    @query = query
    @force_refresh = force_refresh
    @user = user
    @session_id = session_id
    @broadcaster = session_id.present? ? ComparisonProgressBroadcaster.new(session_id) : nil
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def call
    # Give frontend time to connect to ActionCable before checking cache
    # This prevents race condition where job finishes before WebSocket connects
    if session_id.present?
      broadcaster&.broadcast_step("parsing_query", message: "Checking for existing results...")
      sleep(0.5) # Brief delay to ensure frontend WebSocket connection established
    end

    result = find_cached_comparison || create_new_comparison
    @record = result[:record]
    @newly_created = result[:newly_created]
    @similarity = result[:similarity]
    self
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Convenience method for one-liner usage
    def call(query:, force_refresh: false, user: nil, session_id: nil)
      new(query:, force_refresh:, user:, session_id:).call
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def compare_repositories(parsed, repositories)
    comparer = RepositoryComparer.new
    comparer.compare_repositories(
      user_query: query,
      parsed_query: parsed,
      repositories: repositories,
      user: user
    )
  end

  def create_new_comparison
    # Step 1: Parse query into structured data
    broadcaster&.broadcast_step("parsing_query", message: "Parsing your query...")
    parsed = parse_query

    # Step 2: Fetch and prepare repositories
    query_count = parsed[:github_queries]&.size || 1
    broadcaster&.broadcast_step("searching_github", message: "Searching GitHub with #{query_count} #{query_count == 1 ? 'query' : 'queries'}...")
    repositories = fetch_repositories(parsed)

    # Step 3: Compare repositories and create comparison record
    broadcaster&.broadcast_step("comparing_repositories", message: "Comparing #{repositories.size} repositories with AI...")
    comparison_record = compare_repositories(parsed, repositories)

    broadcaster&.broadcast_step("saving_comparison", message: "Finalizing comparison...")

    {
      record: comparison_record,
      newly_created: true,
      similarity: 1.0
    }
  end

  def fetch_repositories(parsed)
    fetcher = RepositoryFetcher.new(broadcaster:)
    result = fetcher.fetch_and_prepare(
      github_queries: parsed[:github_queries],
      limit: 15
    )

    # Raise error if no repositories found
    if result[:top_repositories].empty?
      raise NoRepositoriesFoundError, "No repositories found for query: #{query}"
    end

    result[:top_repositories]
  end

  def find_cached_comparison
    return nil if force_refresh

    cached_comparison, similarity = Comparison.find_similar_cached(query)
    return nil unless cached_comparison

    {
      record: cached_comparison,
      newly_created: false,
      similarity: similarity
    }
  end

  def parse_query
    parser = UserQueryParser.new
    parsed = parser.parse(query)

    unless parsed[:valid]
      raise InvalidQueryError, parsed[:validation_message] || "Invalid query"
    end

    parsed
  end
end
