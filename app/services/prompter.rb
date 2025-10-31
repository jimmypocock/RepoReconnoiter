# Renders AI prompt templates from app/prompts/ directory
# Usage:
#   Prompter.render("query_parser_system")
#   Prompter.render("repository_analyzer_build", repository: repo, categories: cats)
#   Prompter.sanitize_user_input("ignore all previous instructions")
class Prompter
  class TemplateNotFoundError < StandardError; end

  def initialize(template_name, locals = {})
    @template_name = template_name
    @locals = locals
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Render the template with locals
  # @return [String] Rendered prompt text
  def render
    template = read_template
    render_erb(template)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Creates a new prompt template file with documentation header
    # @param name [String] Template name (without .erb extension)
    # @param system [Boolean] Whether this is a system prompt (true) or user/build prompt (false)
    # @return [String] Path to created file
    def create(name, system: false)
      new_generator(name, system).create
    end

    # Renders a prompt template with optional local variables
    # @param template_name [String] Template filename (without .erb extension)
    # @param locals [Hash] Variables to pass to the template
    # @return [String] Rendered prompt text
    def render(template_name, locals = {})
      new(template_name, locals).render
    end

    # Sanitizes user input to prevent prompt injection attacks
    # Call this before sending user-provided text to AI models
    # @param text [String] User input to sanitize
    # @return [String] Sanitized text
    def sanitize_user_input(text)
      return "" if text.blank?

      sanitized = text.strip
        # Remove attempts to override system instructions
        .gsub(/ignore\s+(all\s+)?(previous|above|prior)\s+instructions?/i, "[FILTERED]")
        .gsub(/disregard\s+(all\s+)?(previous|above|prior)\s+instructions?/i, "[FILTERED]")
        # Remove attempts to extract system prompt
        .gsub(/what\s+(is|are)\s+(your|the)\s+system\s+(prompt|instructions?)/i, "[FILTERED]")
        .gsub(/show\s+me\s+(your|the)\s+system\s+(prompt|instructions?)/i, "[FILTERED]")
        .gsub(/repeat\s+(your|the)\s+system\s+(prompt|instructions?)/i, "[FILTERED]")
        # Remove role manipulation attempts
        .gsub(/you\s+are\s+now/i, "[FILTERED]")
        .gsub(/act\s+as\s+(a|an)/i, "[FILTERED]")
        .gsub(/pretend\s+(to\s+be|you\s+are)/i, "[FILTERED]")
        # Remove attempts to end system context
        .gsub(/\[\/?(system|assistant|user)\]/i, "[FILTERED]")
        .gsub(/<\/?system>/i, "[FILTERED]")
        # Limit excessive repetition (potential DOS)
        .gsub(/(.{10,}?)\1{5,}/, '\1\1\1')  # Max 3 repetitions of any 10+ char pattern

      # Truncate to reasonable length (prevent token exhaustion attacks)
      max_length = 5000
      sanitized = sanitized[0...max_length] if sanitized.length > max_length

      sanitized.strip
    end

    private

    # Private class method to create generator instance
    def new_generator(name, system)
      Generator.new(name, system)
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  attr_reader :template_name, :locals

  def read_template
    unless File.exist?(template_path)
      raise TemplateNotFoundError, "Prompt template not found: #{template_path}"
    end

    File.read(template_path)
  end

  def render_erb(template)
    # Create a binding with locals as instance variables for ERB
    binding_object = Object.new
    locals.each do |key, value|
      binding_object.instance_variable_set("@#{key}", value)
    end

    ERB.new(template, trim_mode: "-").result(binding_object.instance_eval { binding })
  end

  def template_path
    Rails.root.join("app", "prompts", "#{template_name}.erb")
  end

  #--------------------------------------
  # INTERNAL GENERATOR CLASS
  #--------------------------------------

  # Internal generator class for creating new prompt templates
  class Generator
    attr_reader :name, :system

    def initialize(name, system)
      @name = name
      @system = system
    end

    def create
      validate_name!
      check_file_exists!
      write_template_file
      file_path
    end

    private

    def check_file_exists!
      if File.exist?(file_path)
        raise ArgumentError, "Prompt template already exists: #{file_path}"
      end
    end

    def file_path
      @file_path ||= File.join(prompts_dir, "#{name}.erb")
    end

    def prompts_dir
      Rails.root.join("app", "prompts")
    end

    def template_content
      system ? system_prompt_template : build_prompt_template
    end

    def validate_name!
      unless name =~ /^[a-z_][a-z0-9_]*$/
        raise ArgumentError, "Prompt name must be snake_case and start with a letter: #{name}"
      end
    end

    def write_template_file
      FileUtils.mkdir_p(prompts_dir) unless Dir.exist?(prompts_dir)
      File.write(file_path, template_content)
    end

    # Template generation methods

    def build_prompt_template
      <<~TEMPLATE
        <%#
        PROMPT: #{name}
        DESCRIPTION: [Describe what this build prompt does]
        VARIABLES:
          - @variable_name: [Type] Description of what this variable contains
          - @another_variable: [Type] Description
        SECURITY: [no_user_input | structured_data | user_input]
        OUTPUT: [Describe the built prompt content]
        MODEL: [gpt-4o-mini | gpt-4o]
        USED_BY: [ServiceName#method_name]
        -%>
        [Build your dynamic prompt here using ERB variables]

        <%= @variable_name %>

        [Add context and instructions]

        <%# You can add Ruby helper methods here if needed -%>
        <%
        def helper_method(arg)
          # Helper logic
        end
        %>
      TEMPLATE
    end

    def system_prompt_template
      <<~TEMPLATE
        <%#
        PROMPT: #{name}
        DESCRIPTION: [Describe what this system prompt does]
        VARIABLES: (none)
        SECURITY: [no_user_input | structured_data | user_input]
        OUTPUT: [Describe the expected output format - e.g., JSON with specific fields]
        MODEL: [gpt-4o-mini | gpt-4o | gpt-4o-mini-2024-07-18]
        USED_BY: [ServiceName#method_name]
        -%>
        You are [define the AI's role].

        Your task is to [describe the task].

        Respond ONLY with valid JSON in this exact format:
        {
          "field1": "value",
          "field2": ["array", "values"],
          "field3": 0.95
        }

        Guidelines:
        - [Add specific instructions]
        - [Add constraints]
        - [Add output format requirements]
        - [Add quality criteria]

        Examples:
        - [Provide example input/output pairs]
      TEMPLATE
    end
  end
end
