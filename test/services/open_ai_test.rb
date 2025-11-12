require "test_helper"

class OpenAiTest < ActiveSupport::TestCase
  setup do
    # Remove monkey-patched chat method from other tests (if it exists)
    # stub_openai_chat in test_helper uses class_eval to globally replace chat()
    # This ensures we're testing the real implementation, not the mock
    OpenAi.class_eval { remove_method(:chat) } if OpenAi.instance_methods(false).include?(:chat)

    # Force class reload to restore original chat method (suppress constant warnings)
    Kernel.silence_warnings do
      load Rails.root.join("app/services/open_ai.rb").to_s
    end

    # Stub the actual HTTP request to OpenAI API
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: {
          choices: [
            { message: { content: "test response" } }
          ],
          usage: {
            prompt_tokens: 100,
            completion_tokens: 50,
            total_tokens: 150
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  #--------------------------------------
  # COST TRACKING TESTS
  #--------------------------------------

  test "chat creates AiCost record for daily rollup" do
    ai = OpenAi.new

    assert_difference "AiCost.count", 1 do
      ai.chat(
        messages: [ { role: "user", content: "test" } ],
        model: "gpt-5-mini",
        track_as: "test_operation"
      )
    end

    cost = AiCost.last
    assert_equal Date.current, cost.date
    assert_equal "gpt-5-mini", cost.model_used
    assert cost.total_cost_usd > 0
    assert_equal 1, cost.total_requests
  end

  test "chat updates existing AiCost record for same day and model" do
    # Create existing cost record for today
    existing_cost = AiCost.create!(
      date: Date.current,
      model_used: "gpt-5-mini",
      total_cost_usd: 0.001,
      total_requests: 1,
      total_input_tokens: 100,
      total_output_tokens: 50
    )

    ai = OpenAi.new

    assert_no_difference "AiCost.count" do
      ai.chat(
        messages: [ { role: "user", content: "test" } ],
        model: "gpt-5-mini"
      )
    end

    existing_cost.reload
    assert_equal 2, existing_cost.total_requests, "Should increment request count"
    assert existing_cost.total_cost_usd > 0.001, "Should add to cost"
    assert existing_cost.total_input_tokens > 100, "Should add input tokens"
    assert existing_cost.total_output_tokens > 50, "Should add output tokens"
  end

  test "chat creates separate AiCost records for different models" do
    ai = OpenAi.new

    # First call with gpt-5-mini
    ai.chat(
      messages: [ { role: "user", content: "test1" } ],
      model: "gpt-5-mini"
    )

    # Second call with gpt-5
    ai.chat(
      messages: [ { role: "user", content: "test2" } ],
      model: "gpt-5"
    )

    assert_equal 2, AiCost.where(date: Date.current).count
    assert_not_nil AiCost.find_by(date: Date.current, model_used: "gpt-5-mini")
    assert_not_nil AiCost.find_by(date: Date.current, model_used: "gpt-5")
  end

  #--------------------------------------
  # MODEL WHITELISTING TESTS
  #--------------------------------------

  test "chat raises error when model not whitelisted" do
    ai = OpenAi.new

    # Should raise error before making API call
    assert_raises(OpenAi::ModelNotWhitelistedError) do
      ai.chat(
        messages: [ { role: "user", content: "test" } ],
        model: "gpt-4" # Not in whitelist
      )
    end
  end

  test "chat accepts whitelisted gpt-5-mini model" do
    ai = OpenAi.new

    # Should not raise error
    response = ai.chat(
      messages: [ { role: "user", content: "test" } ],
      model: "gpt-5-mini"
    )

    assert_not_nil response
  end

  test "chat accepts whitelisted gpt-5 model" do
    ai = OpenAi.new

    # Should not raise error
    response = ai.chat(
      messages: [ { role: "user", content: "test" } ],
      model: "gpt-5"
    )

    assert_not_nil response
  end

  #--------------------------------------
  # COST CALCULATION TESTS
  #--------------------------------------

  test "calculate_cost returns correct cost for gpt-5-mini" do
    cost = OpenAi.calculate_cost(
      model: "gpt-5-mini",
      input_tokens: 1_000_000,
      output_tokens: 1_000_000
    )

    # gpt-5-mini: $0.25/1M input, $2.00/1M output
    # 1M tokens * $0.25/1M = $0.25
    # 1M tokens * $2.00/1M = $2.00
    # Total = $2.25
    assert_in_delta 2.25, cost, 0.000001
  end

  test "calculate_cost returns correct cost for gpt-5" do
    cost = OpenAi.calculate_cost(
      model: "gpt-5",
      input_tokens: 1_000_000,
      output_tokens: 1_000_000
    )

    # gpt-5: $1.25/1M input, $10.00/1M output
    # 1M tokens * $1.25/1M = $1.25
    # 1M tokens * $10.00/1M = $10.00
    # Total = $11.25
    assert_in_delta 11.25, cost, 0.000001
  end

  test "calculate_cost handles fractional tokens correctly" do
    cost = OpenAi.calculate_cost(
      model: "gpt-5-mini",
      input_tokens: 500,
      output_tokens: 250
    )

    # gpt-5-mini: $0.25/1M input, $2.00/1M output
    # 500 tokens * $0.25/1M = $0.000125
    # 250 tokens * $2.00/1M = $0.0005
    # Total = $0.000625
    assert_in_delta 0.000625, cost, 0.000001
  end

  test "calculate_cost raises error for non-whitelisted model" do
    error = assert_raises(OpenAi::ModelNotWhitelistedError) do
      OpenAi.calculate_cost(
        model: "gpt-4",
        input_tokens: 100,
        output_tokens: 50
      )
    end

    assert_match /not whitelisted/, error.message
  end

  #--------------------------------------
  # RESPONSE STRUCTURE TESTS
  #--------------------------------------

  test "chat returns response with choices" do
    ai = OpenAi.new

    response = ai.chat(
      messages: [ { role: "user", content: "test" } ],
      model: "gpt-5-mini"
    )

    assert_respond_to response, :choices
    assert response.choices.length > 0
  end

  test "chat returns response with usage data" do
    ai = OpenAi.new

    response = ai.chat(
      messages: [ { role: "user", content: "test" } ],
      model: "gpt-5-mini"
    )

    assert_respond_to response, :usage
    assert_respond_to response.usage, :prompt_tokens
    assert_respond_to response.usage, :completion_tokens
    assert_operator response.usage.prompt_tokens, :>, 0
    assert_operator response.usage.completion_tokens, :>, 0
  end

  test "chat accepts additional options" do
    ai = OpenAi.new

    # Should not raise error
    response = ai.chat(
      messages: [ { role: "user", content: "test" } ],
      model: "gpt-5-mini",
      temperature: 0.7,
      max_tokens: 100
    )

    assert_not_nil response
  end
end
