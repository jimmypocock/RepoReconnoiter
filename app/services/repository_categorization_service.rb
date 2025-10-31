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

    response = client.chat.completions.create(
      messages: [
        { role: "system", content: Prompt.render("repository_categorization_system") },
        { role: "user", content: Prompt.render("repository_categorization_build", repository: repository, available_categories: available_categories) }
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

end
