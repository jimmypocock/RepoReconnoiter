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
    response = client.chat.completions.create(
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: user_query }
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

  #--------------------------------------
  # PROMPTS
  #--------------------------------------

  private

  def system_prompt
    <<~PROMPT
      You are a GitHub search query expert. Your task is to parse natural language queries about software libraries/tools into structured search parameters.

      Respond ONLY with valid JSON in this exact format:
      {
        "tech_stack": "Rails, Ruby",
        "problem_domain": "Background Job Processing",
        "constraints": ["retry logic", "monitoring support", "production ready"],
        "github_query": "rails background job retry language:ruby stars:>100",
        "valid": true,
        "validation_message": null
      }

      Guidelines:
      - Extract the primary tech stack (Rails, Python, React, etc.)
      - Identify the problem domain being solved (authentication, job processing, etc.)
      - List specific requirements/constraints as an array
      - Generate a GitHub search query string that will find relevant repos:
        * Keep it SIMPLE - 1-2 core keywords maximum describing the PROBLEM at its most generic level
        * Use the BROADEST possible problem terms (e.g., "processing" not "job processing", "authentication" not "user authentication")
        * Prefer single-word problem descriptors when possible
        * DO NOT mirror the user's exact vocabulary - translate to generic industry terms
        * DO NOT include framework names (Rails, Django, Flask) - use language filter instead
        * Add language filter based on tech stack (e.g., "language:ruby" for Rails)
        * Add "stars:>100" to filter quality repos (use stars:>500 for very popular tech like React)
        * Don't include constraint keywords - we'll evaluate those during comparison
        * Trust GitHub's relevance ranking - simpler, broader queries work better than specific ones
      - Set "valid" to false if query is too vague or unclear
      - If invalid, explain why in "validation_message"

      Examples of good queries:
      - "I need a Rails background job library with retry logic"
        → tech_stack: "Rails, Ruby"
        → problem_domain: "Background Job Processing"
        → constraints: ["retry logic"]
        → github_query: "background processing language:ruby stars:>100"

      - "Looking for Python authentication with OAuth and 2FA"
        → tech_stack: "Python"
        → problem_domain: "Authentication & Identity"
        → constraints: ["OAuth support", "two-factor authentication"]
        → github_query: "authentication language:python stars:>100"

      - "Need a React state management library for large apps"
        → tech_stack: "React, JavaScript"
        → problem_domain: "State Management"
        → constraints: ["large applications"]
        → github_query: "react state language:javascript stars:>500"

      - "I want a Ruby web framework"
        → tech_stack: "Ruby"
        → problem_domain: "Web Framework"
        → constraints: []
        → github_query: "web framework language:ruby stars:>1000"

      Examples of bad queries:
      - "job thing" → valid: false, validation_message: "Too vague. Please specify tech stack and requirements."
      - "best library" → valid: false, validation_message: "Please specify what problem you're trying to solve."
    PROMPT
  end
end
