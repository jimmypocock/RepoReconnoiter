class UserQueryParser
  attr_reader :ai

  def initialize
    @ai = OpenAi.new
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Parses natural language query into structured search parameters
  # Returns: { tech_stack:, problem_domain:, constraints:, github_queries:, query_strategy:, valid:, validation_message:, input_tokens:, output_tokens: }
  def parse(user_query)
    # Sanitize user input to prevent prompt injection
    sanitized_query = Prompter.sanitize_user_input(user_query)

    response = ai.chat(
      messages: [
        { role: "system", content: Prompter.render("user_query_parser_system") },
        { role: "user", content: sanitized_query }
      ],
      model: "gpt-4o-mini",
      temperature: 0.3,
      response_format: { type: "json_object" },
      track_as: "query_parsing"
    )

    content = JSON.parse(response.choices[0].message.content)

    {
      tech_stack: content["tech_stack"],
      problem_domain: content["problem_domain"],
      constraints: content["constraints"] || [],
      github_queries: content["github_queries"] || [],
      query_strategy: content["query_strategy"] || "single",
      valid: content["valid"] || false,
      validation_message: content["validation_message"],
      input_tokens: response.usage.prompt_tokens,
      output_tokens: response.usage.completion_tokens
    }
  end
end
