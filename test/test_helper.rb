ENV["RAILS_ENV"] ||= "test"

# Set required environment variables for test environment
ENV["COMPARISON_SIMILARITY_THRESHOLD"] ||= "0.8"
ENV["COMPARISON_CACHE_DAYS"] ||= "7"
ENV["ANALYSIS_DEEP_DAILY_BUDGET"] ||= "0.50"
ENV["ANALYSIS_DEEP_RATE_LIMIT_PER_USER"] ||= "3"
ENV["ANALYSIS_DEEP_EXPIRATION_DAYS"] ||= "30"

require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "ostruct"
require "webmock/minitest"

# Load test support files
Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

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

    # Rails multi-database setup requires manually loading all schemas for parallel workers
    # Our setup: multi-database config (primary, cache, queue, cable) all point to same DATABASE_URL
    # Rails doesn't automatically load all schemas when using multi-database pattern
    parallelize_setup do |worker|
      # Suppress schema loading noise
      ActiveRecord::Base.connection.execute("SET client_min_messages TO WARNING")

      # Check if primary tables exist (indicates schemas already loaded by another worker)
      # This prevents race conditions when multiple workers start simultaneously
      tables = ActiveRecord::Base.connection.tables
      needs_schemas = !tables.include?("ai_costs")

      if needs_schemas
        # Load ALL schemas into the shared database (matching production setup)
        [ "schema.rb", "cache_schema.rb", "queue_schema.rb", "cable_schema.rb" ].each do |schema_file|
          schema_path = Rails.root.join("db", schema_file)
          load(schema_path) if schema_path.exist?
        end
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include test helpers
    include GithubHelpers
    include Heroicon::ApplicationHelper

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

    # Stub OpenAI embeddings API to prevent hitting real API in tests
    def stub_openai_embeddings(embedding: [ 0.1, 0.2, 0.3 ])
      # Stub the embeddings API using WebMock
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return(
          status: 200,
          body: {
            data: [
              { embedding: embedding }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end

# Add Devise test helpers for integration tests
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
