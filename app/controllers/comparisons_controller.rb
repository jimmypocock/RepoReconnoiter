class ComparisonsController < ApplicationController
  def index
    # Clean homepage with search input
  end

  def create
    query = params[:query]

    if query.blank?
      redirect_to root_path, alert: "Please enter a search query"
      return
    end

    # Step 1: Parse query
    parser = UserQueryParser.new
    parsed = parser.parse(query)

    unless parsed[:valid]
      redirect_to root_path, alert: "Invalid query: #{parsed[:validation_message]}"
      return
    end

    # Step 2: Fetch and prepare repositories
    fetcher = RepositoryFetcher.new
    result = fetcher.fetch_and_prepare(
      github_queries: parsed[:github_queries],
      limit: 10
    )

    if result[:top_repositories].empty?
      redirect_to root_path, alert: "No repositories found for your query. Try different keywords."
      return
    end

    # Step 3: Compare repositories
    comparer = RepositoryComparer.new
    @comparison = comparer.compare_repositories(
      user_query: query,
      parsed_query: parsed,
      repositories: result[:top_repositories]
    )

    redirect_to comparison_path(@comparison)
  rescue => e
    Rails.logger.error "Comparison failed: #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to root_path, alert: "Something went wrong. Please try again."
  end

  def show
    @comparison = Comparison.find(params[:id])
    @comparison.increment_view_count!
  end
end
