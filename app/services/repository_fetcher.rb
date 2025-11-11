class RepositoryFetcher
  # Maximum repositories to fetch per comparison (cost control)
  DEFAULT_LIMIT = 10
  MAX_LIMIT = 15

  attr_reader :github, :broadcaster, :user

  def initialize(broadcaster: nil, user: nil)
    @github = Github.new
    @broadcaster = broadcaster
    @user = user
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def fetch_and_prepare(github_queries:, limit: DEFAULT_LIMIT)
    # Enforce maximum limit to prevent runaway costs
    limit = [ [ limit, MAX_LIMIT ].min, 1 ].max  # Clamp between 1 and MAX_LIMIT
    # Step 1: Execute multi-query GitHub search and merge results
    all_repos = execute_searches(github_queries, limit)

    # Broadcast merge completion
    broadcaster&.broadcast_step("merging_results",
      message: "Found #{all_repos.size} #{all_repos.size == 1 ? 'repository' : 'repositories'}, merging results..."
    )

    # Step 2: Sort by stars (quality signal for prioritization)
    sorted_repos = all_repos.sort_by { |r| -r.stargazers_count }

    # Step 3: Save to database using Repository.from_github_api
    repositories = save_repositories(sorted_repos)

    # Step 4: Split into top N (for comparison) and others (lighter recommendations)
    top_repos = repositories.first(limit)
    other_repos = repositories[limit..-1] || []

    # Step 5: Analyze top N synchronously (wait for completion)
    analyze_repositories(top_repos)

    # Return structured data for comparison
    {
      top_repositories: prepare_repo_data(top_repos, analyzed: true),
      other_repositories: prepare_repo_data(other_repos, analyzed: false),
      total_found: all_repos.size,
      queries_executed: github_queries.size
    }
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def analyze_repositories(repositories)
    analyzer = RepositoryAnalyzer.new
    category_matcher = CategoryMatcher.new

    repositories.each_with_index do |repo, index|
      # Broadcast progress for this repository
      broadcaster&.broadcast_step("analyzing_repositories",
        current: index + 1,
        total: repositories.size,
        message: "Analyzing #{repo.full_name}..."
      )

      next unless repo.needs_analysis?

      begin
        result = analyzer.analyze(repo)

        # Create analysis record (defaults to Analysis base class)
        repo.analyses.create!(
          model_used: "gpt-4o-mini",
          summary: result[:summary],
          use_cases: result[:use_cases],
          input_tokens: result[:input_tokens],
          output_tokens: result[:output_tokens],
          is_current: true,
          user:
        )

        # Create category associations using CategoryMatcher
        result[:categories].each do |cat|
          # Find or create category with embedding and normalization
          category = category_matcher.find_or_create(
            name: cat["name"],
            category_type: cat["category_type"]
          )

          repo.repository_categories.create!(
            category_id: category.id,
            confidence_score: cat["confidence"],
            assigned_by: "ai"
          )
        end

        # Auto-assign technology category from GitHub language field
        if repo.language.present?
          # Find or create the category using CategoryMatcher
          category = category_matcher.find_or_create(
            name: repo.language,
            category_type: "technology"
          )

          # Only create association if it doesn't already exist
          unless repo.repository_categories.exists?(category_id: category.id)
            repo.repository_categories.create!(
              category_id: category.id,
              confidence_score: 1.0,
              assigned_by: "github_language"
            )

            Rails.logger.info "  📌 Added technology category from GitHub language: #{repo.language}"
          end
        end

        # Update last_analyzed_at timestamp
        repo.update!(last_analyzed_at: Time.current)

        # Reload to pick up new associations
        repo.reload

        Rails.logger.info "✅ Analyzed: #{repo.full_name}"
      rescue => e
        Rails.logger.error "❌ Analysis failed for #{repo.full_name}: #{e.message}"
      end
    end
  end

  def calculate_quality_signals(repo)
    age_days = (Date.current - repo.github_created_at.to_date).to_i
    age_days = 1 if age_days.zero? # Avoid division by zero

    {
      stars: repo.stargazers_count,
      forks: repo.forks_count,
      open_issues: repo.open_issues_count,
      last_updated: repo.github_pushed_at,
      age_days: age_days,
      stars_per_day: (repo.stargazers_count.to_f / age_days).round(2),
      is_archived: repo.archived,
      is_disabled: repo.disabled,
      language: repo.language,
      has_analysis: repo.analyses.current.any?
    }
  end

  def execute_searches(queries, limit)
    all_repos = []
    seen_full_names = Set.new

    queries.each_with_index do |search_query, idx|
      begin
        results = github.search(search_query, per_page: limit)

        # Dedupe: only add repos we haven't seen yet
        new_repos = results.items.reject { |repo| seen_full_names.include?(repo.full_name) }

        new_repos.each do |repo|
          all_repos << repo
          seen_full_names.add(repo.full_name)
        end

        Rails.logger.info "Query #{idx + 1}: Found #{results.total_count} total, added #{new_repos.size} new (#{all_repos.size} unique so far)"
      rescue => e
        Rails.logger.error "GitHub search error for query '#{search_query}': #{e.message}"
      end
    end

    all_repos
  end

  def prepare_repo_data(repositories, analyzed:)
    repositories.map do |repo|
      {
        repository: repo,
        analyzed: analyzed,
        quality_signals: calculate_quality_signals(repo)
      }
    end
  end

  def save_repositories(github_repos)
    repositories = []

    github_repos.each do |gh_repo|
      begin
        # Use Repository.from_github_api to create or update
        repo = Repository.from_github_api(gh_repo.to_attrs)
        repo.save!
        repositories << repo
      rescue => e
        Rails.logger.error "Failed to save repository #{gh_repo.full_name}: #{e.message}"
      end
    end

    repositories
  end
end
