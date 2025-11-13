# API v1 Admin Stats Controller
# Requires user JWT authentication + admin role
#
# Endpoints:
#   GET /api/v1/admin/stats - Get platform-wide statistics
#
module Api
  module V1
    module Admin
      class StatsController < BaseController
        # Requires both API key and user JWT with admin role
        before_action :authenticate_user_token!
        before_action :require_admin!

        #--------------------------------------
        # ACTIONS
        #--------------------------------------

        # GET /api/v1/admin/stats
        # Returns platform-wide statistics and AI spending information
        #
        # Headers:
        #   Authorization: Bearer <API_KEY>
        #   X-User-Token: <JWT>
        #
        # Response (200 OK):
        #   {
        #     "data": {
        #       "ai_spending": {
        #         "today": 0.02,
        #         "this_week": 0.15,
        #         "this_month": 0.45,
        #         "total": 2.35,
        #         "projected_month": 0.90
        #       },
        #       "budget": {
        #         "monthly_limit": 10.0,
        #         "remaining": 9.55,
        #         "percentage_used": 4.5,
        #         "status": "healthy"
        #       },
        #       "platform": {
        #         "comparisons_count": 150,
        #         "repositories_count": 500,
        #         "total_views": 3200
        #       },
        #       "spend_by_model": [
        #         { "model": "gpt-4o-mini", "cost": 0.30, "percentage": 66.7 },
        #         { "model": "gpt-4o", "cost": 0.15, "percentage": 33.3 }
        #       ],
        #       "spend_by_user": [
        #         { "username": "johndoe", "cost": 0.25, "percentage": 55.6 },
        #         { "username": "janedoe", "cost": 0.20, "percentage": 44.4 }
        #       ]
        #     }
        #   }
        #
        def index
          presenter = StatsPresenter.new

          render_success(
            data: {
              ai_spending: {
                today: presenter.ai_spend_today.round(2),
                this_week: presenter.ai_spend_this_week.round(2),
                this_month: presenter.ai_spend_this_month.round(2),
                total: presenter.ai_spend_total.round(2),
                projected_month: presenter.ai_spend_projected.round(2)
              },
              budget: {
                monthly_limit: StatsPresenter::BUDGET_MONTHLY,
                remaining: presenter.budget_remaining.round(2),
                percentage_used: presenter.budget_percentage_used,
                status: presenter.budget_status
              },
              platform: {
                comparisons_count: presenter.comparisons_count,
                repositories_count: presenter.repositories_count,
                total_views: presenter.total_views
              },
              spend_by_model: presenter.spend_by_model,
              spend_by_user: presenter.spend_by_user
            }
          )
        end

        private

        #--------------------------------------
        # PRIVATE METHODS
        #--------------------------------------

        def require_admin!
          unless current_user.admin?
            render_error(
              message: "Admin access required",
              errors: [ "You must be an admin to access this endpoint" ],
              status: :forbidden
            )
          end
        end
      end
    end
  end
end
