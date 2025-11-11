class ProfileController < ApplicationController
  before_action :authenticate_user!

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def destroy
    # Soft delete: mark user as deleted but keep data for referential integrity
    current_user.update(deleted_at: Time.current)
    sign_out current_user

    redirect_to root_path, notice: "Your account has been deleted."
  end

  def show
    # Simple approach: just show most recent items without pagination
    # Most users won't have enough comparisons/analyses to need pagination
    @comparisons = current_user.comparisons.order(created_at: :desc).limit(20)
    @analyses = current_user.analyses.where(type: "AnalysisDeep").order(created_at: :desc).limit(20)

    # Usage stats
    @comparisons_this_month = current_user.comparisons_count_this_month
    @analyses_this_month = current_user.analyses_count_this_month
    @remaining_comparisons = current_user.remaining_comparisons_today
    @remaining_analyses = current_user.remaining_analyses_today
    @total_cost_spent = current_user.total_ai_cost_spent
  end
end
