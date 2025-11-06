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

  def prepare_repository_data(repositories)
    repositories.map do |item|
      repo = item[:repository]
      {
        repository: repo,
        quality_signals: item[:quality_signals],
        analysis: repo.analysis_current # Get current Tier 1 analysis
      }
    end
  end

  def create_comparison_record(user_query:, parsed_query:, comparison_data:, repositories:, input_tokens:, output_tokens:, user: nil)
    # Calculate cost for gpt-4o
    # Pricing: $2.50 per 1M input tokens, $10.00 per 1M output tokens
    input_cost = (input_tokens / 1_000_000.0) * 2.50
    output_cost = (output_tokens / 1_000_000.0) * 10.00
    total_cost = input_cost + output_cost

    # Create comparison record
    comparison = Comparison.create!(
      user: user,
      user_query: user_query,
      tech_stack: parsed_query[:tech_stack],
      problem_domain: parsed_query[:problem_domain],
      constraints: parsed_query[:constraints],
      github_search_query: parsed_query[:github_queries].join(" | "),
      recommended_repo_full_name: comparison_data["recommended_repo"],
      recommendation_reasoning: comparison_data["recommendation_reasoning"],
      ranking_results: comparison_data, # Store full JSON response
      repos_compared_count: comparison_data["ranking"].size,
      model_used: "gpt-4o",
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      cost_usd: total_cost
    )

    # Create comparison_repositories join records
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

    # Infer and link categories from problem_domain
    link_comparison_categories(comparison, parsed_query[:problem_domain])

    comparison
  end

  def link_comparison_categories(comparison, problem_domain)
    return unless problem_domain.present?

    # Try to find matching category by fuzzy matching on name/slug
    # Simple approach: find categories that contain words from problem_domain
    words = problem_domain.downcase.split(/\s+/)

    matching_categories = Category.where(category_type: "problem_domain").select do |category|
      category_words = category.name.downcase.split(/\s+/)
      # Match if any word overlaps
      (words & category_words).any?
    end

    # Link found categories
    matching_categories.each do |category|
      comparison.comparison_categories.find_or_create_by!(
        category: category,
        assigned_by: "inferred"
      )
    end

    # If no match found, create a new category
    if matching_categories.empty?
      category = Category.find_or_create_by!(slug: problem_domain.parameterize) do |c|
        c.name = problem_domain.titleize
        c.category_type = "problem_domain"
        c.description = "Auto-generated from comparison query"
      end

      comparison.comparison_categories.create!(
        category: category,
        assigned_by: "ai"
      )
    end
  end
end
