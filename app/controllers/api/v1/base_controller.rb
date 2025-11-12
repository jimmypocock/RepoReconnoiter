# Base controller for all API v1 endpoints
# Handles common API concerns: error responses, JSON formatting, authentication
#
# All API controllers should inherit from this class:
#   class Api::V1::ComparisonsController < Api::V1::BaseController
#
module Api
  module V1
    class BaseController < ActionController::API
      # ActionController::API is a stripped-down controller optimized for APIs:
      # - No CSRF protection (not needed for stateless APIs)
      # - No view rendering (JSON only)
      # - No cookies/session by default
      # - No asset pipeline middleware

      # Include Pagy for pagination support
      include Pagy::Method

      # JSON responses only
      respond_to :json

      #--------------------------------------
      # AUTHENTICATION
      #--------------------------------------

      # Require API key authentication for all endpoints
      # Override with `skip_before_action :authenticate_api_key!` in child controllers if needed
      before_action :authenticate_api_key!

      #--------------------------------------
      # ERROR HANDLING
      #--------------------------------------

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      #--------------------------------------
      # AUTHENTICATION HELPERS
      #--------------------------------------

      # Authenticate API key from Authorization header
      # Returns 401 Unauthorized if missing or invalid
      def authenticate_api_key!
        auth_header = request.headers["Authorization"]

        unless auth_header&.start_with?("Bearer ")
          return render_error(
            message: "API key required",
            errors: [ "Missing Authorization header. Expected format: 'Authorization: Bearer <API_KEY>'" ],
            status: :unauthorized
          )
        end

        raw_key = auth_header.sub("Bearer ", "")
        @current_api_key = ApiKey.authenticate(raw_key)

        unless @current_api_key
          return render_error(
            message: "Invalid API key",
            errors: [ "The provided API key is invalid or has been revoked" ],
            status: :unauthorized
          )
        end

        # Track usage asynchronously (doesn't slow down request)
        ApiKeyUsageTracker.track_async(@current_api_key.id)
      end

      # Current authenticated API key
      def current_api_key
        @current_api_key
      end

      #--------------------------------------
      # RESPONSE HELPERS
      #--------------------------------------

      # Standard success response
      # @param data [Object] The data to return
      # @param meta [Hash] Optional metadata (pagination, etc.)
      # @param status [Symbol] HTTP status code
      def render_success(data:, meta: {}, status: :ok)
        response = { data: data }
        response[:meta] = meta if meta.present?

        render json: response, status: status
      end

      # Standard error response
      # @param message [String] Error message
      # @param errors [Array<String>] Detailed error list
      # @param status [Symbol] HTTP status code
      def render_error(message:, errors: [], status: :unprocessable_entity)
        render json: {
          error: {
            message: message,
            details: errors
          }
        }, status: status
      end

      def render_not_found(exception)
        render_error(
          message: "Resource not found",
          errors: [ exception.message ],
          status: :not_found
        )
      end

      def render_bad_request(exception)
        render_error(
          message: "Invalid request parameters",
          errors: [ exception.message ],
          status: :bad_request
        )
      end
    end
  end
end
