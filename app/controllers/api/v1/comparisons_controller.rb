# API v1 Comparisons Controller
# Requires API key authentication (Authorization: Bearer <API_KEY>)
#
# Endpoints:
#   GET /api/v1/comparisons - List comparisons with filtering, search, pagination
#   POST /api/v1/comparisons - Create comparison (async, requires user auth)
#
module Api
  module V1
    class ComparisonsController < BaseController
      # User authentication required for create action only
      before_action :authenticate_user_token!, only: [ :create ]

      #--------------------------------------
      # ACTIONS
      #--------------------------------------

      # POST /api/v1/comparisons
      # Creates a comparison asynchronously and returns session info for tracking
      #
      # Headers:
      #   Authorization: Bearer <API_KEY>
      #   X-User-Token: <JWT>
      #
      # Body:
      #   { "query": "Rails background job library" }
      #
      # Response (202 Accepted):
      #   {
      #     "session_id": "uuid",
      #     "status": "processing",
      #     "websocket_url": "ws://localhost:3001/cable",
      #     "status_url": "/api/v1/comparisons/status/uuid"
      #   }
      #
      def create
        query = params[:query]

        # Validate query presence and length (same as web UI)
        if query.blank? || query.to_s.length > 500
          return render_error(
            message: "Invalid query",
            errors: [ "Query must be between 1 and 500 characters" ],
            status: :unprocessable_entity
          )
        end

        # Generate session ID for tracking
        session_id = SecureRandom.uuid

        # Create status tracking record with cost reservation (prevents race condition)
        ComparisonStatus.create!(
          session_id: session_id,
          user: current_user,
          status: :processing,
          pending_cost_usd: Comparison::ESTIMATED_COST
        )

        # Queue background job
        CreateComparisonJob.perform_later(current_user.id, query, session_id)

        # Return 202 Accepted with tracking info
        render json: {
          session_id: session_id,
          status: "processing",
          websocket_url: websocket_url,
          status_url: v1_comparison_status_url(session_id)
        }, status: :accepted
      end

      # GET /api/v1/comparisons/status/:session_id
      # Returns the current status of an async comparison creation
      #
      # Response (processing):
      #   { "status": "processing" }
      #
      # Response (completed):
      #   {
      #     "status": "completed",
      #     "comparison_id": 123,
      #     "comparison_url": "/comparisons/123"
      #   }
      #
      # Response (failed):
      #   {
      #     "status": "failed",
      #     "error_message": "No repositories found"
      #   }
      #
      def status
        status_record = ComparisonStatus.find_by!(session_id: params[:session_id])

        response = { status: status_record.status }

        case status_record.status
        when "completed"
          response[:comparison_id] = status_record.comparison_id
          response[:comparison_url] = comparison_url(status_record.comparison_id)
        when "failed"
          response[:error_message] = status_record.error_message
        end

        render json: response
      end

      # GET /api/v1/comparisons/:id
      # Returns a single comparison with full details
      #
      # Response (200 OK):
      #   {
      #     "data": {
      #       "id": 123,
      #       "user_query": "Rails background job library",
      #       "normalized_query": "rails background job",
      #       "technologies": ["Ruby", "Rails"],
      #       "problem_domains": ["Background Jobs"],
      #       "architecture_patterns": ["Queue-based"],
      #       "repos_compared_count": 5,
      #       "recommended_repo": "sidekiq/sidekiq",
      #       "view_count": 42,
      #       "created_at": "2025-11-12T00:00:00Z",
      #       "updated_at": "2025-11-12T00:00:00Z",
      #       "categories": [...],
      #       "repositories": [...]
      #     }
      #   }
      #
      def show
        comparison = Comparison.includes(:categories, :repositories).find(params[:id])

        render_success(data: ComparisonSerializer.new(comparison).as_json)
      end

      # GET /api/v1/comparisons
      # Returns paginated list of comparisons with optional filtering
      #
      # Query parameters:
      #   - search: Search term for fuzzy matching
      #   - date: Filter by date range (week, month)
      #   - sort: Sort order (recent, popular)
      #   - page: Page number (default: 1)
      #   - per_page: Items per page (default: 20, max: 100)
      #
      def index
        # Use existing presenter for filtering/search logic
        presenter = SearchComparisonsPresenter.new(filter_params)

        # Eager load associations to avoid N+1 (MUST be before pagy)
        scope = presenter.comparisons.includes(:categories, :repositories)

        # Apply pagination (Pagy v43 uses :limit instead of :items)
        @pagy, comparisons = pagy(scope, limit: per_page, page: params[:page])

        render_success(
          data: ComparisonSerializer.collection(comparisons),
          meta: pagination_meta
        )
      end

      private

      #--------------------------------------
      # PRIVATE METHODS
      #--------------------------------------

      def filter_params
        params.permit(:search, :date, :sort, :page, :per_page)
      end

      def per_page
        per = params[:per_page]&.to_i || 20
        [ per, 100 ].min # Cap at 100 items per page
      end

      def pagination_meta
        # Use Pagy::Offset's built-in properties
        # Note: Pagy::Offset uses .previous instead of .prev
        {
          pagination: {
            page: @pagy.page,
            per_page: @pagy.limit,
            total_pages: @pagy.pages,
            total_count: @pagy.count,
            next_page: @pagy.next,
            prev_page: @pagy.previous
          }
        }
      end

      def websocket_url
        if Rails.env.production?
          "wss://reporeconnoiter.com/cable"
        else
          "ws://localhost:3001/cable"
        end
      end
    end
  end
end
