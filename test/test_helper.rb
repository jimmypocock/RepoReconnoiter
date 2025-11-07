ENV["RAILS_ENV"] ||= "test"

# Set required environment variables for test environment
ENV["COMPARISON_SIMILARITY_THRESHOLD"] ||= "0.8"
ENV["COMPARISON_CACHE_DAYS"] ||= "7"

require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "ostruct"
require "webmock/minitest"

# Block all HTTP requests during tests (prevents accidental API calls)
# Allow localhost for test server (Capybara, Puma)
WebMock.disable_net_connect!(allow_localhost: true)

# Stub credentials for test environment
Rails.application.credentials.define_singleton_method(:openai) do
  OpenStruct.new(api_key: "test_openai_key")
end

# Configure OmniAuth for testing
OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Stub OpenAI API calls to prevent hitting real API in tests
    # Call this in your test setup or individual tests
    def stub_openai_chat(response_content: '{"github_queries":["test query"],"query_strategy":"single","valid":true}')
      mock_response = OpenStruct.new(
        choices: [
          OpenStruct.new(
            message: OpenStruct.new(content: response_content)
          )
        ],
        usage: OpenStruct.new(
          prompt_tokens: 100,
          completion_tokens: 50,
          total_tokens: 150
        )
      )

      # Stub the chat method on OpenAi instances
      OpenAi.class_eval do
        define_method(:chat) do |**args|
          mock_response
        end
      end
    end

    # Stub GitHub API calls to prevent hitting real API in tests
    def stub_github_search
      # Return empty search results
      mock_result = OpenStruct.new(items: [])

      Github.class_eval do
        define_method(:search) do |*args, **kwargs|
          mock_result
        end
      end
    end
  end
end
