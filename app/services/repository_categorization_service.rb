class RepositoryCategorizationService
  attr_reader :client

  def initialize
    @client = OpenAI::Client.new(
      api_key: Rails.application.credentials.openai&.api_key
    )
  end

  #--------------------------------------
  # TIER 1: CATEGORIZATION
  #--------------------------------------

  # Categorizes a repository using gpt-4o-mini
  # Returns: { categories: [...], summary: "...", use_cases: "...", input_tokens:, output_tokens: }
  def categorize_repository(repository)
    available_categories = Category.all.group_by(&:category_type)

    prompt = build_categorization_prompt(repository, available_categories)

    response = client.chat.completions.create(
      messages: [
        { role: "system", content: system_prompt_for_categorization },
        { role: "user", content: prompt }
      ],
      model: "gpt-4o-mini",
      temperature: 0.3,
      response_format: { type: "json_object" }
    )

    content = JSON.parse(response.choices[0].message.content)

    {
      categories: content["categories"] || [],
      summary: content["summary"],
      use_cases: content["use_cases"],
      input_tokens: response.usage.prompt_tokens,
      output_tokens: response.usage.completion_tokens
    }
  end

  #--------------------------------------
  # TIER 2: DEEP DIVE (Placeholder)
  #--------------------------------------

  def deep_dive_analysis(repository)
    # TODO: Implement with gpt-4o
    raise NotImplementedError, "Tier 2 analysis not yet implemented"
  end

  #--------------------------------------
  # PROMPTS
  #--------------------------------------

  private

  def system_prompt_for_categorization
    <<~PROMPT
      You are an expert software engineer analyzing GitHub repositories.
      Your task is to categorize repositories and provide brief summaries.

      Respond ONLY with valid JSON in this exact format:
      {
        "categories": [
          {
            "name": "Category Name",
            "slug": "category-slug",
            "category_type": "problem_domain|architecture_pattern|maturity",
            "confidence": 0.95
          }
        ],
        "summary": "One sentence describing what this repository does",
        "use_cases": "Brief description of when you'd use this (2-3 sentences)"
      }

      Guidelines:
      - Create 3-6 categories that best describe what this repository does
      - You MUST include AT LEAST ONE category from each type: problem_domain, architecture_pattern, maturity
      - Prefer using available categories listed below when they fit
      - Create NEW categories if the available ones don't accurately capture what this repo does
      - New category names should be clear, specific, and broadly applicable to other repos
      - Use kebab-case for slugs
      - Confidence should be 0.0-1.0 (only include categories you're confident about)
      - Be concise and accurate
      - Base your analysis on the repository metadata provided
    PROMPT
  end

  def build_categorization_prompt(repository, available_categories)
    <<~PROMPT
      Analyze this GitHub repository:

      **Repository:** #{repository.full_name}
      **Description:** #{repository.description || "No description provided"}
      **Language:** #{repository.language || "Unknown"}
      **Stars:** #{repository.stargazers_count}
      **Topics:** #{repository.topics.join(", ") if repository.topics.any?}
      **Created:** #{repository.github_created_at&.strftime("%B %Y")}
      **Last Updated:** #{repository.github_updated_at&.strftime("%B %Y")}
      #{repository.homepage_url.present? ? "**Homepage:** #{repository.homepage_url}" : ""}

      ---

      **Available Categories:**

      Problem Domains:
      #{format_categories(available_categories["problem_domain"])}

      Architecture Patterns:
      #{format_categories(available_categories["architecture_pattern"])}

      Maturity Levels:
      #{format_categories(available_categories["maturity"])}

      ---

      Based on this information, categorize the repository and provide a summary.
    PROMPT
  end

  def format_categories(categories)
    return "None available" if categories.blank?

    categories.map { |c| "- #{c.slug}" }.join("\n")
  end
end
