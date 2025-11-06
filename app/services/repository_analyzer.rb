class RepositoryAnalyzer
  attr_reader :ai

  def initialize
    @ai = OpenAi.new
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Tier 1: Analyzes and categorizes a repository using gpt-4o-mini
  # Returns: { categories: [...], summary: "...", use_cases: "...", input_tokens:, output_tokens: }
  def analyze(repository)
    available_categories = Category.all.group_by(&:category_type)

    response = ai.chat(
      messages: [
        { role: "system", content: Prompter.render("repository_analyzer_system") },
        { role: "user", content: Prompter.render("repository_analyzer_build", repository:, available_categories:) }
      ],
      model: "gpt-4o-mini",
      temperature: 0.3,
      response_format: { type: "json_object" },
      track_as: "repository_analysis"
    )

    # Validate output for suspicious patterns (defense-in-depth)
    raw_content = response.choices[0].message.content
    Prompter.validate_output(raw_content)

    content = JSON.parse(raw_content)

    {
      categories: content["categories"] || [],
      summary: content["summary"],
      use_cases: content["use_cases"],
      input_tokens: response.usage.prompt_tokens,
      output_tokens: response.usage.completion_tokens
    }
  end

  # Tier 2: Deep dive analysis (not yet implemented)
  # Returns: Detailed analysis with README content and issue analysis
  def deep_dive_analysis(repository)
    # TODO: Implement with gpt-4o
    raise NotImplementedError, "Tier 2 analysis not yet implemented"
  end

  class << self
    delegate :analyze, to: :new
  end
end
