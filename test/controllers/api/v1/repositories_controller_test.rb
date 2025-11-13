require "test_helper"

module Api
  module V1
    class RepositoriesControllerTest < ActionDispatch::IntegrationTest
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

        # Create test repositories
        @repo1 = repositories(:one)
        @repo2 = repositories(:two)
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
      # INDEX TESTS
      #--------------------------------------

      test "GET /api/v1/repositories requires API key" do
        get v1_repositories_path, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "API key required", json["error"]["message"]
      end

      test "GET /api/v1/repositories returns list of repositories" do
        get v1_repositories_path, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json["data"].is_a?(Array)
        assert json["meta"]["pagination"].present?
      end

      test "GET /api/v1/repositories supports search filtering" do
        get v1_repositories_path, params: { search: @repo1.name }, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        repo_names = json["data"].map { |r| r["full_name"] }
        assert_includes repo_names, @repo1.full_name
      end

      test "GET /api/v1/repositories supports language filtering" do
        get v1_repositories_path, params: { language: @repo1.language }, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        json["data"].each do |repo|
          assert_equal @repo1.language, repo["language"]
        end
      end

      test "GET /api/v1/repositories supports min_stars filtering" do
        get v1_repositories_path, params: { min_stars: 1000 }, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        json["data"].each do |repo|
          assert_operator repo["stargazers_count"], :>=, 1000
        end
      end

      test "GET /api/v1/repositories supports sorting by stars" do
        get v1_repositories_path, params: { sort: "stars" }, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        stars = json["data"].map { |r| r["stargazers_count"] }
        assert_equal stars.sort.reverse, stars
      end

      test "GET /api/v1/repositories returns pagination metadata" do
        get v1_repositories_path, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        pagination = json["meta"]["pagination"]

        assert pagination.key?("page")
        assert pagination.key?("per_page")
        assert pagination.key?("total_pages")
        assert pagination.key?("total_count")
      end

      test "GET /api/v1/repositories respects per_page parameter" do
        get v1_repositories_path, params: { per_page: 5 }, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_operator json["data"].size, :<=, 5
      end

      test "GET /api/v1/repositories caps per_page at 100" do
        get v1_repositories_path, params: { per_page: 200 }, headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_equal 100, json["meta"]["pagination"]["per_page"]
      end

      #--------------------------------------
      # SHOW TESTS
      #--------------------------------------

      test "GET /api/v1/repositories/:id requires API key" do
        get v1_repository_path(@repo1), as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "API key required", json["error"]["message"]
      end

      test "GET /api/v1/repositories/:id returns repository details" do
        get v1_repository_path(@repo1), headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        data = json["data"]

        assert_equal @repo1.id, data["id"]
        assert_equal @repo1.full_name, data["full_name"]
        assert_equal @repo1.description, data["description"]
        assert_equal @repo1.stargazers_count, data["stargazers_count"]
        assert_equal @repo1.language, data["language"]
      end

      test "GET /api/v1/repositories/:id includes categories" do
        get v1_repository_path(@repo1), headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json["data"]["categories"].is_a?(Array)
      end

      test "GET /api/v1/repositories/:id includes analyses" do
        get v1_repository_path(@repo1), headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json["data"]["analyses"].is_a?(Array)
      end

      test "GET /api/v1/repositories/:id returns 404 for non-existent repository" do
        get v1_repository_path(id: 999999), headers: auth_headers, as: :json

        assert_response :not_found
        json = JSON.parse(response.body)
        assert_equal "Repository not found", json["error"]["message"]
      end

      #--------------------------------------
      # ANALYZE TESTS
      #--------------------------------------

      test "POST /api/v1/repositories/:id/analyze requires API key" do
        post analyze_v1_repository_path(@repo1), as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "API key required", json["error"]["message"]
      end

      test "POST /api/v1/repositories/:id/analyze requires user JWT token" do
        post analyze_v1_repository_path(@repo1), headers: auth_headers, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "User authentication required", json["error"]["message"]
      end

      test "POST /api/v1/repositories/:id/analyze creates analysis job" do
        post analyze_v1_repository_path(@repo1), headers: user_headers(@user), as: :json

        assert_response :accepted
        json = JSON.parse(response.body)

        assert json["session_id"].present?
        assert_equal "processing", json["status"]
        assert json["websocket_url"].present?
        assert json["status_url"].present?
      end

      test "POST /api/v1/repositories/:id/analyze creates AnalysisStatus record" do
        assert_difference "AnalysisStatus.count", 1 do
          post analyze_v1_repository_path(@repo1), headers: user_headers(@user), as: :json
        end

        status = AnalysisStatus.last
        assert_equal @user.id, status.user_id
        assert_equal @repo1.id, status.repository_id
        assert_equal "processing", status.status
      end

      test "POST /api/v1/repositories/:id/analyze reserves budget with pending_cost_usd" do
        post analyze_v1_repository_path(@repo1), headers: user_headers(@user), as: :json

        status = AnalysisStatus.last
        assert_equal AnalysisDeep::ESTIMATED_COST, status.pending_cost_usd
      end

      test "POST /api/v1/repositories/:id/analyze enqueues CreateDeepAnalysisJob" do
        assert_enqueued_jobs 1, only: CreateDeepAnalysisJob do
          post analyze_v1_repository_path(@repo1), headers: user_headers(@user), as: :json
        end
      end

      test "POST /api/v1/repositories/:id/analyze returns 403 when budget exceeded" do
        # Stub the budget check to return false
        AnalysisDeep.stub :can_create_today?, false do
          post analyze_v1_repository_path(@repo1), headers: user_headers(@user), as: :json

          assert_response :forbidden
          json = JSON.parse(response.body)
          assert_equal "Daily analysis budget exceeded", json["error"]["message"]
        end
      end

      test "POST /api/v1/repositories/:id/analyze returns 429 when user rate limit exceeded" do
        # Stub the user rate limit check to return false
        AnalysisDeep.stub :user_can_create_today?, false do
          post analyze_v1_repository_path(@repo1), headers: user_headers(@user), as: :json

          assert_response :too_many_requests
          json = JSON.parse(response.body)
          assert_equal "Rate limit exceeded", json["error"]["message"]
        end
      end

      #--------------------------------------
      # STATUS TESTS
      #--------------------------------------

      test "GET /api/v1/repositories/status/:session_id requires API key" do
        session_id = SecureRandom.uuid
        AnalysisStatus.create!(
          session_id: session_id,
          user: @user,
          repository: @repo1,
          status: :processing
        )

        get v1_repository_status_path(session_id), as: :json

        assert_response :unauthorized
      end

      test "GET /api/v1/repositories/status/:session_id returns processing status" do
        session_id = SecureRandom.uuid
        AnalysisStatus.create!(
          session_id: session_id,
          user: @user,
          repository: @repo1,
          status: :processing
        )

        get v1_repository_status_path(session_id), headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_equal "processing", json["status"]
      end

      test "GET /api/v1/repositories/status/:session_id returns completed status with repository info" do
        session_id = SecureRandom.uuid
        status = AnalysisStatus.create!(
          session_id: session_id,
          user: @user,
          repository: @repo1,
          status: :completed
        )

        get v1_repository_status_path(session_id), headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_equal "completed", json["status"]
        assert_equal @repo1.id, json["repository_id"]
        assert json["repository_url"].present?
      end

      test "GET /api/v1/repositories/status/:session_id returns failed status with error message" do
        session_id = SecureRandom.uuid
        status = AnalysisStatus.create!(
          session_id: session_id,
          user: @user,
          repository: @repo1,
          status: :failed,
          error_message: "Repository not found"
        )

        get v1_repository_status_path(session_id), headers: auth_headers, as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert_equal "failed", json["status"]
        assert_equal "Repository not found", json["error_message"]
      end

      test "GET /api/v1/repositories/status/:session_id returns 404 for non-existent session" do
        get v1_repository_status_path("non-existent-session"), headers: auth_headers, as: :json

        assert_response :not_found
      end
    end
  end
end
