# OpenAI API wrapper with automatic cost tracking and model whitelisting
# Usage:
#   ai = OpenAi.new
#   response = ai.chat(messages: [...], model: "gpt-4o-mini", track_as: "query_parsing")
#   content = response.choices[0].message.content  # Same API as OpenAI::Client
class OpenAi
  class ModelNotWhitelistedError < StandardError; end

  # Whitelisted models with pricing (per million tokens)
  # Source: https://openai.com/api/pricing/
  MODELS = {
    "gpt-4o-mini" => {
      input_cost_per_million: 0.150,
      output_cost_per_million: 0.600,
      description: "Fast, cheap model for categorization and parsing"
    },
    "gpt-4o" => {
      input_cost_per_million: 2.50,
      output_cost_per_million: 10.00,
      description: "Powerful model for deep analysis and comparisons"
    }
  }.freeze

  attr_reader :client

  def initialize
    @client = OpenAI::Client.new(
      api_key: Rails.application.credentials.openai&.api_key
    )
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Call OpenAI chat completion API with automatic cost tracking
  # @param messages [Array<Hash>] Array of message hashes with role and content
  # @param model [String] Model identifier (must be whitelisted)
  # @param track_as [String, nil] Cost type for tracking (auto-inferred if nil)
  # @param options [Hash] Additional options passed to OpenAI API
  # @return [OpenAI::Client::Response] Raw OpenAI response object
  def chat(messages:, model:, track_as: nil, **options)
    validate_model!(model)

    response = client.chat.completions.create(
      model: model,
      messages: messages,
      **options
    )

    track_cost(response, model, track_as)

    response
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Calculate cost for given token usage
    # @param model [String] Model identifier
    # @param input_tokens [Integer] Number of input tokens
    # @param output_tokens [Integer] Number of output tokens
    # @return [Float] Cost in USD
    def calculate_cost(model:, input_tokens:, output_tokens:)
      pricing = model_pricing(model)

      (input_tokens * pricing[:input_cost_per_million] / 1_000_000.0) +
        (output_tokens * pricing[:output_cost_per_million] / 1_000_000.0)
    end

    private

    # Get model pricing information
    # @param model [String] Model identifier
    # @return [Hash] Pricing information
    def model_pricing(model)
      MODELS[model] || raise(ModelNotWhitelistedError, "Model #{model} not whitelisted")
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def infer_cost_type
    # Try to infer from call stack
    caller_location = caller_locations.find do |loc|
      loc.path.include?("app/") && !loc.path.include?("open_ai.rb")
    end

    if caller_location
      # Extract class/method from path (e.g., "UserQueryParser#parse")
      path = caller_location.path
      label = caller_location.label

      if path.include?("services/")
        service_name = File.basename(path, ".rb")
        "#{service_name}##{label}"
      else
        label
      end
    else
      "unknown"
    end
  end

  def track_cost(response, model, track_as)
    usage = response.usage
    return unless usage # Safety check

    input_tokens = usage.prompt_tokens
    output_tokens = usage.completion_tokens

    cost_usd = self.class.calculate_cost(
      model: model,
      input_tokens: input_tokens,
      output_tokens: output_tokens
    )

    # Update daily rollup
    today = Date.current
    ai_cost = AiCost.find_or_initialize_by(date: today, model_used: model)

    ai_cost.total_requests ||= 0
    ai_cost.total_input_tokens ||= 0
    ai_cost.total_output_tokens ||= 0
    ai_cost.total_cost_usd ||= 0

    ai_cost.total_requests += 1
    ai_cost.total_input_tokens += input_tokens
    ai_cost.total_output_tokens += output_tokens
    ai_cost.total_cost_usd += cost_usd

    ai_cost.save!

    Rails.logger.info "💰 AI Cost tracked: #{model} - #{track_as || infer_cost_type} - $#{cost_usd.round(6)} (#{input_tokens} in / #{output_tokens} out)"
  rescue => e
    # Log error but don't fail the request
    Rails.logger.error "Failed to track AI cost: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end

  def validate_model!(model)
    return if MODELS.key?(model)

    raise ModelNotWhitelistedError,
          "Model '#{model}' is not whitelisted. Allowed models: #{MODELS.keys.join(', ')}"
  end
end
