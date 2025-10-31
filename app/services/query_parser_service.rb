class QueryParserService
  attr_reader :client

  def initialize
    @client = OpenAI::Client.new(
      api_key: Rails.application.credentials.openai&.api_key
    )
  end

  #--------------------------------------
  # PUBLIC METHODS
  #--------------------------------------

  # Parses natural language query into structured search parameters
  # Returns: { tech_stack:, problem_domain:, constraints:, github_query:, valid:, input_tokens:, output_tokens: }
  def parse(user_query)
    # Sanitize user input to prevent prompt injection
    sanitized_query = Prompt.sanitize_user_input(user_query)

    response = client.chat.completions.create(
      messages: [
        { role: "system", content: Prompt.render("query_parser_system") },
        { role: "user", content: sanitized_query }
      ],
      model: "gpt-4o-mini",
      temperature: 0.3,
      response_format: { type: "json_object" }
    )

    content = JSON.parse(response.choices[0].message.content)

    {
      tech_stack: content["tech_stack"],
      problem_domain: content["problem_domain"],
      constraints: content["constraints"] || [],
      github_query: content["github_query"],
      valid: content["valid"] || false,
      validation_message: content["validation_message"],
      input_tokens: response.usage.prompt_tokens,
      output_tokens: response.usage.completion_tokens
    }
  end

end
