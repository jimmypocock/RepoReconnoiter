# API v1 Authentication Controller
# Handles GitHub OAuth token exchange for JWT tokens
#
# Endpoints:
#   POST /api/v1/auth/exchange - Exchange GitHub OAuth token for JWT
#
module Api
  module V1
    class AuthController < BaseController
      # Skip API key authentication for the exchange endpoint would be wrong
      # We DO want API key auth (proves request is from our Next.js app)
      # But we don't want user token auth (user isn't logged in yet)

      #--------------------------------------
      # ACTIONS
      #--------------------------------------

      # POST /api/v1/auth/exchange
      # Exchange GitHub OAuth token for JWT
      #
      # Request body:
      #   { "github_token": "gho_..." }
      #
      # Response:
      #   {
      #     "jwt": "eyJ...",
      #     "user": {
      #       "id": 1,
      #       "github_id": 12345,
      #       "github_username": "username",
      #       "email": "user@example.com",
      #       "avatar_url": "https://...",
      #       "name": "User Name",
      #       "admin": false
      #     }
      #   }
      #
      def exchange
        github_token = params[:github_token]

        if github_token.blank?
          return render_error(
            message: "GitHub token required",
            errors: [ "Missing github_token in request body" ],
            status: :bad_request
          )
        end

        # Verify GitHub token and get user data
        github_user = fetch_github_user(github_token)

        unless github_user
          return render_error(
            message: "Invalid GitHub token",
            errors: [ "Could not verify GitHub token or fetch user data" ],
            status: :unauthorized
          )
        end

        # Check if user is whitelisted
        unless whitelisted?(github_user[:id])
          return render_error(
            message: "Access denied",
            errors: [ "Your GitHub account is not whitelisted for access" ],
            status: :forbidden
          )
        end

        # Create or update user record
        user = find_or_create_user(github_user)

        # Generate JWT
        jwt = JsonWebToken.encode({ user_id: user.id })

        # Return JWT and user data
        render_success(
          data: {
            jwt: jwt,
            user: {
              id: user.id,
              github_id: user.github_id,
              github_username: user.github_username,
              email: user.email,
              avatar_url: user.github_avatar_url,
              name: user.github_name,
              admin: user.admin?
            }
          }
        )
      end

      private

      #--------------------------------------
      # PRIVATE METHODS
      #--------------------------------------

      # Fetch GitHub user data using OAuth token
      # @param token [String] GitHub OAuth token
      # @return [Hash, nil] GitHub user data or nil if invalid
      def fetch_github_user(token)
        client = Octokit::Client.new(access_token: token)
        github_user = client.user

        {
          id: github_user.id,
          login: github_user.login,
          email: github_user.email,
          avatar_url: github_user.avatar_url,
          name: github_user.name
        }
      rescue Octokit::Unauthorized, Octokit::Error => e
        Rails.logger.warn("GitHub token verification failed: #{e.message}")
        nil
      end

      # Check if GitHub user is whitelisted
      # @param github_id [Integer] GitHub user ID
      # @return [Boolean]
      def whitelisted?(github_id)
        WhitelistedUser.exists?(github_id: github_id)
      end

      # Find or create user from GitHub data
      # @param github_user [Hash] GitHub user data
      # @return [User]
      def find_or_create_user(github_user)
        User.find_or_create_by!(github_id: github_user[:id]) do |user|
          user.github_username = github_user[:login]
          user.email = github_user[:email] || "#{github_user[:login]}@users.noreply.github.com"
          user.github_avatar_url = github_user[:avatar_url]
          user.github_name = github_user[:name]
        end.tap do |user|
          # Update user data on every login (GitHub data might have changed)
          user.update(
            github_username: github_user[:login],
            email: github_user[:email] || "#{github_user[:login]}@users.noreply.github.com",
            github_avatar_url: github_user[:avatar_url],
            github_name: github_user[:name]
          )
        end
      end
    end
  end
end
