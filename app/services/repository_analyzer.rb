class RepositoryAnalyzer
  attr_reader :ai

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def initialize
    @ai = OpenAi.new
  end

  # Analyzes and categorizes a repository using gpt-5-mini
  # Returns: { categories: [...], summary: "...", use_cases: "...", input_tokens:, output_tokens: }
  def analyze(repository)
    available_categories = Category.all.group_by(&:category_type)

    response = ai.chat(
      messages: [
        { role: "system", content: Prompter.render("repository_analyzer_system") },
        { role: "user", content: Prompter.render("repository_analyzer_build", repository:, available_categories:) }
      ],
      model: "gpt-5-mini",
      reasoning_effort: "minimal",
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

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    delegate :analyze, to: :new
  end
end
