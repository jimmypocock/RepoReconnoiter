# API v1 Repositories Controller
# Requires API key authentication (Authorization: Bearer <API_KEY>)
#
# Endpoints:
#   GET /api/v1/repositories - List repositories with filtering, search, pagination
#   GET /api/v1/repositories/:id - Show single repository with details
#   POST /api/v1/repositories/:id/analyze - Create deep analysis (async, requires user auth)
#
module Api
  module V1
    class RepositoriesController < BaseController
      # User authentication required for analyze action only
      before_action :authenticate_user_token!, only: [ :analyze ]
      before_action :set_repository, only: [ :show, :analyze ]

      #--------------------------------------
      # ACTIONS
      #--------------------------------------

      # GET /api/v1/repositories
      # Returns paginated list of repositories with optional filtering
      #
      # Query parameters:
      #   - search: Search term for name/description
      #   - language: Filter by programming language
      #   - min_stars: Minimum stargazers count
      #   - sort: Sort order (stars, updated, created) default: updated
      #   - page: Page number (default: 1)
      #   - per_page: Items per page (default: 20, max: 100)
      #
      def index
        scope = Repository.includes(:categories, :analyses)

        # Apply search filter
        if params[:search].present?
          search_term = "%#{params[:search]}%"
          scope = scope.where(
            "full_name ILIKE ? OR description ILIKE ?",
            search_term, search_term
          )
        end

        # Apply language filter
        scope = scope.where(language: params[:language]) if params[:language].present?

        # Apply minimum stars filter
        if params[:min_stars].present?
          min_stars = params[:min_stars].to_i
          scope = scope.where("stargazers_count >= ?", min_stars)
        end

        # Apply sorting
        scope = case params[:sort]
        when "stars"
          scope.order(stargazers_count: :desc)
        when "created"
          scope.order(github_created_at: :desc)
        else
          scope.order(github_updated_at: :desc) # Default: most recently updated
        end

        # Apply pagination (Pagy v43 uses :limit instead of :items)
        @pagy, repositories = pagy(scope, limit: per_page, page: params[:page])

        render_success(
          data: RepositorySerializer.collection(repositories),
          meta: pagination_meta
        )
      end

      # GET /api/v1/repositories/:id
      # Returns a single repository with full details
      #
      # Response (200 OK):
      #   {
      #     "data": {
      #       "id": 123,
      #       "full_name": "sidekiq/sidekiq",
      #       "description": "Simple, efficient background processing for Ruby",
      #       "stargazers_count": 13000,
      #       "language": "Ruby",
      #       "html_url": "https://github.com/sidekiq/sidekiq",
      #       "categories": [...],
      #       "analyses": [...]
      #     }
      #   }
      #
      def show
        render_success(data: RepositorySerializer.new(@repository).as_json)
      end

      # POST /api/v1/repositories/:id/analyze
      # Triggers a deep analysis asynchronously and returns session info for tracking
      #
      # Headers:
      #   Authorization: Bearer <API_KEY>
      #   X-User-Token: <JWT>
      #
      # Response (202 Accepted):
      #   {
      #     "session_id": "uuid",
      #     "status": "processing",
      #     "websocket_url": "ws://localhost:3001/cable",
      #     "status_url": "/api/v1/repositories/status/uuid"
      #   }
      #
      # Response (403 Forbidden):
      #   {
      #     "error": {
      #       "message": "Daily analysis budget exceeded",
      #       "details": ["Please try again tomorrow"]
      #     }
      #   }
      #
      def analyze
        # Check daily budget
        unless AnalysisDeep.can_create_today?
          return render_error(
            message: "Daily analysis budget exceeded",
            errors: [ "Please try again tomorrow" ],
            status: :forbidden
          )
        end

        # Check user rate limit
        unless AnalysisDeep.user_can_create_today?(current_user)
          remaining = AnalysisDeep::RATE_LIMIT_PER_USER - AnalysisDeep.count_for_user_today(current_user)
          return render_error(
            message: "Rate limit exceeded",
            errors: [ "You have reached your daily limit of #{AnalysisDeep::RATE_LIMIT_PER_USER} deep analyses" ],
            status: :too_many_requests
          )
        end

        # Generate session ID for tracking
        session_id = SecureRandom.uuid

        # Create status tracking record with cost reservation (prevents race condition)
        AnalysisStatus.create!(
          session_id: session_id,
          user: current_user,
          repository: @repository,
          status: :processing,
          pending_cost_usd: AnalysisDeep::ESTIMATED_COST
        )

        # Queue background job
        CreateDeepAnalysisJob.perform_later(current_user.id, @repository.id, session_id)

        # Return 202 Accepted with tracking info
        render json: {
          session_id: session_id,
          status: "processing",
          websocket_url: websocket_url,
          status_url: v1_repository_status_url(session_id)
        }, status: :accepted
      end

      # GET /api/v1/repositories/status/:session_id
      # Returns the current status of an async deep analysis
      #
      # Response (processing):
      #   { "status": "processing" }
      #
      # Response (completed):
      #   {
      #     "status": "completed",
      #     "repository_id": 123,
      #     "repository_url": "/repositories/123"
      #   }
      #
      # Response (failed):
      #   {
      #     "status": "failed",
      #     "error_message": "Repository not found on GitHub"
      #   }
      #
      def status
        status_record = AnalysisStatus.find_by!(session_id: params[:session_id])

        response = { status: status_record.status }

        case status_record.status
        when "completed"
          response[:repository_id] = status_record.repository_id
          response[:repository_url] = v1_repository_url(status_record.repository_id)
        when "failed"
          response[:error_message] = status_record.error_message
        end

        render json: response
      end

      private

      #--------------------------------------
      # PRIVATE METHODS
      #--------------------------------------

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

      def per_page
        per = params[:per_page]&.to_i || 20
        [ per, 100 ].min # Cap at 100 items per page
      end

      def set_repository
        @repository = Repository.includes(:categories, :analyses).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Repository not found",
          errors: [ "Repository with ID #{params[:id]} does not exist" ],
          status: :not_found
        )
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
