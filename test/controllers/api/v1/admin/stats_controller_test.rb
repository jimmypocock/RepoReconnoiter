require "test_helper"

module Api
  module V1
    module Admin
      class StatsControllerTest < ActionDispatch::IntegrationTest
        #--------------------------------------
        # SETUP
        #--------------------------------------

        def setup
          # Create a test API key
          result = ApiKey.generate(name: "Test API Key")
          @api_key = result[:api_key]
          @raw_key = result[:raw_key]

          # Create admin and non-admin users
          @admin = users(:one)
          @admin.update!(github_id: ENV.fetch("ALLOWED_ADMIN_GITHUB_IDS", "1").split(",").first.to_i)
          @non_admin = users(:two)
        end

        def teardown
          @api_key&.destroy
        end

        # Helper to add Authorization header
        def auth_headers
          { "Authorization" => "Bearer #{@raw_key}" }
        end

        # Helper to add user JWT token
        def user_headers(user)
          jwt = JsonWebToken.encode({ user_id: user.id })
          auth_headers.merge("X-User-Token" => jwt)
        end

        #--------------------------------------
        # AUTHENTICATION TESTS
        #--------------------------------------

        test "GET /api/v1/admin/stats requires API key" do
          get v1_admin_stats_path, as: :json

          assert_response :unauthorized
          json = JSON.parse(response.body)
          assert_equal "API key required", json["error"]["message"]
        end

        test "GET /api/v1/admin/stats requires user JWT token" do
          get v1_admin_stats_path, headers: auth_headers, as: :json

          assert_response :unauthorized
          json = JSON.parse(response.body)
          assert_equal "User authentication required", json["error"]["message"]
        end

        test "GET /api/v1/admin/stats requires admin role" do
          get v1_admin_stats_path, headers: user_headers(@non_admin), as: :json

          assert_response :forbidden
          json = JSON.parse(response.body)
          assert_equal "Admin access required", json["error"]["message"]
        end

        test "GET /api/v1/admin/stats accepts admin user" do
          get v1_admin_stats_path, headers: user_headers(@admin), as: :json

          assert_response :success
        end

        #--------------------------------------
        # STATS DATA TESTS
        #--------------------------------------

        test "GET /api/v1/admin/stats returns AI spending data" do
          get v1_admin_stats_path, headers: user_headers(@admin), as: :json

          assert_response :success
          json = JSON.parse(response.body)
          ai_spending = json["data"]["ai_spending"]

          assert ai_spending.key?("today")
          assert ai_spending.key?("this_week")
          assert ai_spending.key?("this_month")
          assert ai_spending.key?("total")
          assert ai_spending.key?("projected_month")

          # All should be present and numeric-ish
          assert_not_nil ai_spending["today"]
          assert_not_nil ai_spending["this_week"]
          assert_not_nil ai_spending["this_month"]
          assert_not_nil ai_spending["total"]
          assert_not_nil ai_spending["projected_month"]

          # Should be able to convert to float
          assert ai_spending["today"].to_f >= 0
          assert ai_spending["this_week"].to_f >= 0
        end

        test "GET /api/v1/admin/stats returns budget data" do
          get v1_admin_stats_path, headers: user_headers(@admin), as: :json

          assert_response :success
          json = JSON.parse(response.body)
          budget = json["data"]["budget"]

          assert budget.key?("monthly_limit")
          assert budget.key?("remaining")
          assert budget.key?("percentage_used")
          assert budget.key?("status")

          # Verify values are present
          assert_equal 10.0, budget["monthly_limit"]
          assert_not_nil budget["remaining"]
          assert_not_nil budget["percentage_used"]
          assert_not_nil budget["status"]

          # Should be able to convert to float
          assert budget["remaining"].to_f >= 0
          assert budget["percentage_used"].to_f >= 0

          # Status should be valid
          assert [ "healthy", "warning", "critical", "exceeded" ].include?(budget["status"].to_s)
        end

        test "GET /api/v1/admin/stats returns platform counts" do
          get v1_admin_stats_path, headers: user_headers(@admin), as: :json

          assert_response :success
          json = JSON.parse(response.body)
          platform = json["data"]["platform"]

          assert platform.key?("comparisons_count")
          assert platform.key?("repositories_count")
          assert platform.key?("total_views")

          # All should be integers
          assert_kind_of Integer, platform["comparisons_count"]
          assert_kind_of Integer, platform["repositories_count"]
          assert_kind_of Integer, platform["total_views"]
        end

        test "GET /api/v1/admin/stats returns spend by model breakdown" do
          get v1_admin_stats_path, headers: user_headers(@admin), as: :json

          assert_response :success
          json = JSON.parse(response.body)
          spend_by_model = json["data"]["spend_by_model"]

          assert spend_by_model.is_a?(Array)
          # Each item should have model, cost, percentage keys if there's data
          if spend_by_model.any?
            first_model = spend_by_model.first
            assert first_model.key?("model")
            assert first_model.key?("cost")
            assert first_model.key?("percentage")
          end
        end

        test "GET /api/v1/admin/stats returns spend by user breakdown" do
          get v1_admin_stats_path, headers: user_headers(@admin), as: :json

          assert_response :success
          json = JSON.parse(response.body)
          spend_by_user = json["data"]["spend_by_user"]

          assert spend_by_user.is_a?(Array)
          # Limited to 10 users
          assert_operator spend_by_user.size, :<=, 10
        end
      end
    end
  end
end
