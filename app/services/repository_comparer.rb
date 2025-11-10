class RepositoryComparer
  attr_reader :ai

  def initialize
    @ai = OpenAi.new
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Tier 3: Compares multiple repositories and creates comparison record
  # Returns: Comparison model instance with all associations
  def compare_repositories(user_query:, parsed_query:, repositories:, user: nil)
    # Prepare repository data with analyses
    repo_data = prepare_repository_data(repositories)

    # Call AI to compare
    response = ai.chat(
      messages: [
        { role: "system", content: Prompter.render("repository_comparer_system") },
        { role: "user", content: Prompter.render("repository_comparer_build",
          user_query: user_query,
          parsed_query: parsed_query,
          repositories: repo_data
        ) }
      ],
      model: "gpt-4o",
      temperature: 0.3,
      response_format: { type: "json_object" },
      track_as: "repository_comparison"
    )

    # Validate output for suspicious patterns (defense-in-depth)
    raw_content = response.choices[0].message.content
    Prompter.validate_output(raw_content)

    # Parse AI response
    content = JSON.parse(raw_content)

    # Create comparison record and associations
    create_comparison_record(
      user_query: user_query,
      parsed_query: parsed_query,
      comparison_data: content,
      repositories: repositories,
      input_tokens: response.usage.prompt_tokens,
      output_tokens: response.usage.completion_tokens,
      user: user
    )
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def add_common_categories(comparison, repositories, type:, threshold:)
    category_counts = Hash.new(0)

    repositories.each do |item|
      repo = item[:repository]
      repo.categories.where(category_type: type).each do |category|
        category_counts[category] += 1
      end
    end

    total_repos = repositories.size
    min_count = (total_repos * threshold).ceil

    category_counts.each do |category, count|
      next unless count >= min_count

      frequency_ratio = count.to_f / total_repos

      comparison.comparison_categories.find_or_create_by!(category: category) do |cc|
        cc.assigned_by = :inherited
        cc.confidence_score = frequency_ratio.round(2)
      end
    end
  end

  def add_query_problem_domain(comparison, problem_domain)
    return unless problem_domain.present?

    category_matcher = CategoryMatcher.new
    category = category_matcher.find_or_create(
      name: problem_domain,
      category_type: "problem_domain"
    )

    comparison.comparison_categories.find_or_create_by!(category: category) do |cc|
      cc.assigned_by = :ai
      cc.confidence_score = 1.0
    end
  end

  def add_top_repo_categories(comparison, top_repos)
    top_repos.each_with_index do |item, index|
      repo = item[:repository]
      confidence = case index
                   when 0 then 1.0
                   when 1 then 0.95
                   when 2 then 0.90
                   else 0.85
                   end

      repo.categories.each do |category|
        comparison.comparison_categories.find_or_create_by!(category: category) do |cc|
          cc.assigned_by = :inherited
          cc.confidence_score = confidence
        end
      end
    end
  end

  def create_comparison_record(user_query:, parsed_query:, comparison_data:, repositories:, input_tokens:, output_tokens:, user: nil)
    input_cost = (input_tokens / 1_000_000.0) * 2.50
    output_cost = (output_tokens / 1_000_000.0) * 10.00
    total_cost = input_cost + output_cost

    comparison = Comparison.create!(
      user: user,
      user_query: user_query,
      technologies: parsed_query[:tech_stack],
      problem_domains: parsed_query[:problem_domain],
      constraints: parsed_query[:constraints],
      github_search_query: parsed_query[:github_queries].join(" | "),
      recommended_repo_full_name: comparison_data["recommended_repo"],
      recommendation_reasoning: comparison_data["recommendation_reasoning"],
      ranking_results: comparison_data,
      repos_compared_count: comparison_data["ranking"].size,
      model_used: "gpt-4o",
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      cost_usd: total_cost
    )

    comparison_data["ranking"].each do |ranking_item|
      repo = repositories.find { |r| r[:repository].full_name == ranking_item["repo_full_name"] }
      next unless repo

      comparison.comparison_repositories.create!(
        repository: repo[:repository],
        rank: ranking_item["rank"],
        score: ranking_item["score"],
        pros: ranking_item["pros"],
        cons: ranking_item["cons"],
        fit_reasoning: ranking_item["fit_reasoning"]
      )
    end

    link_comparison_categories(comparison, parsed_query, repositories)

    comparison
  end

  def link_comparison_categories(comparison, parsed_query, repositories)
    add_query_problem_domain(comparison, parsed_query[:problem_domain])
    add_top_repo_categories(comparison, repositories.first(3))
    add_common_categories(comparison, repositories, type: :technology, threshold: 0.3)
    add_common_categories(comparison, repositories, type: :problem_domain, threshold: 0.5)
    add_common_categories(comparison, repositories, type: :architecture_pattern, threshold: 0.5)
  end

  def prepare_repository_data(repositories)
    repositories.map do |item|
      repo = item[:repository]
      {
        repository: repo,
        quality_signals: item[:quality_signals],
        analysis: repo.analysis_current
      }
    end
  end
end
