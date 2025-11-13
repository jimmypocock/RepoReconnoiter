require "test_helper"

module Api
  module V1
    class ProfileControllerTest < ActionDispatch::IntegrationTest
      #--------------------------------------
      # SETUP
      #--------------------------------------

      def setup
        # Create a test API key
        result = ApiKey.generate(name: "Test API Key")
        @api_key = result[:api_key]
        @raw_key = result[:raw_key]

        # Create test user
        @user = users(:one)
      end

      def teardown
        @api_key&.destroy
      end

      # Helper to add Authorization header
      def auth_headers
        { "Authorization" => "Bearer #{@raw_key}" }
      end

      # Helper to add user JWT token
      def user_headers(user = @user)
        jwt = JsonWebToken.encode({ user_id: user.id })
        auth_headers.merge("X-User-Token" => jwt)
      end

      #--------------------------------------
      # AUTHENTICATION TESTS
      #--------------------------------------

      test "GET /api/v1/profile requires API key" do
        get v1_profile_path, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "API key required", json["error"]["message"]
      end

      test "GET /api/v1/profile requires user JWT token" do
        get v1_profile_path, headers: auth_headers, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "User authentication required", json["error"]["message"]
      end

      test "GET /api/v1/profile accepts valid API key + JWT" do
        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
      end

      #--------------------------------------
      # PROFILE DATA TESTS
      #--------------------------------------

      test "GET /api/v1/profile returns user information" do
        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        user_data = json["data"]["user"]

        assert_equal @user.id, user_data["id"]
        assert_equal @user.email, user_data["email"]
        assert_equal @user.github_username, user_data["github_username"]
        assert_equal @user.github_id, user_data["github_id"]
        assert_equal @user.github_avatar_url, user_data["github_avatar_url"]
        assert_equal @user.admin?, user_data["admin"]
      end

      test "GET /api/v1/profile returns usage stats" do
        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        stats = json["data"]["stats"]

        assert stats.key?("comparisons_this_month")
        assert stats.key?("analyses_this_month")
        assert stats.key?("remaining_comparisons_today")
        assert stats.key?("remaining_analyses_today")
        assert stats.key?("total_cost_spent")

        # Stats should be numeric
        assert_kind_of Integer, stats["comparisons_this_month"]
        assert_kind_of Integer, stats["analyses_this_month"]
        assert_kind_of Numeric, stats["total_cost_spent"]
      end

      test "GET /api/v1/profile returns recent comparisons" do
        # Create a comparison for this user
        comparison = Comparison.create!(
          user_query: "Test query",
          normalized_query: "test",
          repos_compared_count: 3
        )
        @user.comparisons << comparison

        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        recent_comparisons = json["data"]["recent_comparisons"]

        assert recent_comparisons.is_a?(Array)
        # Find our comparison in the list
        our_comparison = recent_comparisons.find { |c| c["id"] == comparison.id }
        assert_not_nil our_comparison
        assert_equal "Test query", our_comparison["user_query"]
        assert_equal 3, our_comparison["repos_compared_count"]
        assert our_comparison.key?("created_at")
      end

      test "GET /api/v1/profile returns recent analyses" do
        # Create a repository and analysis
        repo = repositories(:one)
        analysis = AnalysisDeep.create!(
          repository: repo,
          user: @user,
          model_used: "gpt-5-mini",
          readme_analysis: "Test analysis",
          input_tokens: 100,
          output_tokens: 50,
          is_current: true
        )

        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        recent_analyses = json["data"]["recent_analyses"]

        assert recent_analyses.is_a?(Array)
        # Find our analysis in the list
        our_analysis = recent_analyses.find { |a| a["id"] == analysis.id }
        assert_not_nil our_analysis
        assert_equal repo.full_name, our_analysis["repository_name"]
        assert_equal "gpt-5-mini", our_analysis["model_used"]
        assert our_analysis.key?("created_at")
      end

      test "GET /api/v1/profile limits recent items to 20" do
        # Create 25 comparisons
        25.times do |i|
          comparison = Comparison.create!(
            user_query: "Query #{i}",
            normalized_query: "query #{i}",
            repos_compared_count: 1
          )
          @user.comparisons << comparison
        end

        get v1_profile_path, headers: user_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        recent_comparisons = json["data"]["recent_comparisons"]

        assert_equal 20, recent_comparisons.size
      end
    end
  end
end
