require "test_helper"

module Api
  module V1
    class AuthControllerTest < ActionDispatch::IntegrationTest
      #--------------------------------------
      # SETUP
      #--------------------------------------

      def setup
        # Create API key for authentication
        result = ApiKey.generate(name: "Test API Key")
        @api_key = result[:api_key]
        @raw_api_key = result[:raw_key]

        # Create whitelisted user
        @whitelisted_user = whitelisted_users(:one)

        # GitHub API mock data
        @github_token = "gho_test_token_123"
        @github_user_data = {
          id: @whitelisted_user.github_id,
          login: "testuser",
          email: "test@example.com",
          avatar_url: "https://avatars.githubusercontent.com/u/12345",
          name: "Test User"
        }
      end

      def teardown
        @api_key&.destroy
      end

      def auth_headers
        { "Authorization" => "Bearer #{@raw_api_key}" }
      end

      #--------------------------------------
      # POST /api/v1/auth/exchange TESTS
      #--------------------------------------

      test "POST /api/v1/auth/exchange requires API key" do
        post v1_auth_exchange_path, params: { github_token: @github_token }, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "API key required", json["error"]["message"]
      end

      test "POST /api/v1/auth/exchange requires github_token parameter" do
        post v1_auth_exchange_path, headers: auth_headers, as: :json

        assert_response :bad_request
        json = JSON.parse(response.body)
        assert_equal "GitHub token required", json["error"]["message"]
      end

      test "POST /api/v1/auth/exchange returns 401 for invalid GitHub token" do
        # Mock failed GitHub API call
        stub_request(:get, "https://api.github.com/user")
          .with(headers: { "Authorization" => "token invalid_token" })
          .to_return(status: 401)

        post v1_auth_exchange_path,
             headers: auth_headers,
             params: { github_token: "invalid_token" },
             as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "Invalid GitHub token", json["error"]["message"]
      end

      test "POST /api/v1/auth/exchange returns 403 for non-whitelisted user" do
        # Mock successful GitHub API call with non-whitelisted user
        non_whitelisted_github_id = 99999
        stub_request(:get, "https://api.github.com/user")
          .with(headers: { "Authorization" => "token #{@github_token}" })
          .to_return(
            status: 200,
            body: {
              id: non_whitelisted_github_id,
              login: "nonwhitelisted",
              email: "nonwhitelisted@example.com",
              avatar_url: "https://example.com/avatar.png",
              name: "Non Whitelisted"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        post v1_auth_exchange_path,
             headers: auth_headers,
             params: { github_token: @github_token },
             as: :json

        assert_response :forbidden
        json = JSON.parse(response.body)
        assert_equal "Access denied", json["error"]["message"]
        assert_includes json["error"]["details"][0], "not whitelisted"
      end

      test "POST /api/v1/auth/exchange creates new user for whitelisted GitHub account" do
        # Mock successful GitHub API call
        stub_request(:get, "https://api.github.com/user")
          .with(headers: { "Authorization" => "token #{@github_token}" })
          .to_return(
            status: 200,
            body: @github_user_data.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Ensure user doesn't exist (use a unique github_id for this test)
        new_github_id = 88888888  # Very unique ID unlikely to conflict
        test_github_data = @github_user_data.merge(id: new_github_id, login: "newuser88888888")

        # Whitelist the user
        WhitelistedUser.find_or_create_by!(github_id: new_github_id) do |wl|
          wl.github_username = test_github_data[:login]
        end

        # Update the GitHub API mock
        stub_request(:get, "https://api.github.com/user")
          .with(headers: { "Authorization" => "token new_user_token" })
          .to_return(
            status: 200,
            body: test_github_data.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        assert_difference("User.count", 1) do
          post v1_auth_exchange_path,
               headers: auth_headers,
               params: { github_token: "new_user_token" },
               as: :json
        end

        assert_response :success
        json = JSON.parse(response.body)

        # Verify JWT is present
        assert json["data"]["jwt"].present?
        jwt = json["data"]["jwt"]

        # Verify JWT can be decoded
        payload = JsonWebToken.decode(jwt)
        assert payload[:user_id].present?
        assert payload[:exp].present?

        # Verify user data
        user_data = json["data"]["user"]
        assert_equal test_github_data[:id], user_data["github_id"]
        assert_equal test_github_data[:login], user_data["github_username"]
        assert_equal test_github_data[:email], user_data["email"]
        assert_equal test_github_data[:avatar_url], user_data["avatar_url"]
        assert_equal test_github_data[:name], user_data["name"]
        assert_equal false, user_data["admin"]

        # Verify user was created in database
        user = User.find_by(github_id: test_github_data[:id])
        assert user.present?
        assert_equal test_github_data[:login], user.github_username
      end

      test "POST /api/v1/auth/exchange updates existing user data" do
        # Use a unique github_id for this test
        update_test_github_id = 77777
        update_github_data = @github_user_data.merge(id: update_test_github_id)

        # Whitelist the user
        WhitelistedUser.find_or_create_by!(github_id: update_test_github_id) do |wl|
          wl.github_username = update_github_data[:login]
        end

        # Mock successful GitHub API call
        stub_request(:get, "https://api.github.com/user")
          .with(headers: { "Authorization" => "token update_token" })
          .to_return(
            status: 200,
            body: update_github_data.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Create user with old data
        user = User.create!(
          github_id: update_test_github_id,
          github_username: "oldusername",
          email: "old@example.com",
          github_avatar_url: "https://old-avatar.com",
          github_name: "Old Name"
        )

        assert_no_difference("User.count") do
          post v1_auth_exchange_path,
               headers: auth_headers,
               params: { github_token: "update_token" },
               as: :json
        end

        assert_response :success

        # Verify user data was updated
        user.reload
        assert_equal update_github_data[:login], user.github_username
        assert_equal update_github_data[:email], user.email
        assert_equal update_github_data[:avatar_url], user.github_avatar_url
        assert_equal update_github_data[:name], user.github_name
      end

      test "POST /api/v1/auth/exchange returns admin: true for admin users" do
        # Mock successful GitHub API call
        stub_request(:get, "https://api.github.com/user")
          .with(headers: { "Authorization" => "token #{@github_token}" })
          .to_return(
            status: 200,
            body: @github_user_data.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Create admin user
        admin_github_id = 999888
        WhitelistedUser.create!(github_id: admin_github_id, github_username: "admin")

        # Stub admin check
        ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: admin_github_id.to_s do
          user = User.create!(
            github_id: admin_github_id,
            github_username: "admin",
            email: "admin@example.com"
          )

          # Update mock to return admin's GitHub ID
          stub_request(:get, "https://api.github.com/user")
            .with(headers: { "Authorization" => "token admin_token" })
            .to_return(
              status: 200,
              body: { id: admin_github_id, login: "admin", email: "admin@example.com", avatar_url: "https://example.com", name: "Admin" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          post v1_auth_exchange_path,
               headers: auth_headers,
               params: { github_token: "admin_token" },
               as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert_equal true, json["data"]["user"]["admin"]
        end
      end
    end
  end
end
