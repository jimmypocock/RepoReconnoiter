# API v1 Comparisons Controller
# Public read-only access to comparisons (no auth required for index)
#
# Endpoints:
#   GET /api/v1/comparisons - List comparisons with filtering, search, pagination
#
module Api
  module V1
    class ComparisonsController < BaseController
      #--------------------------------------
      # PUBLIC ACTIONS
      #--------------------------------------

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
    end
  end
end
