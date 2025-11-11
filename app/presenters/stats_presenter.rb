class StatsPresenter
  #--------------------------------------
  # CONFIGURATION
  #--------------------------------------

  BUDGET_MONTHLY = 10.0

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def ai_spend_projected
    @ai_spend_projected ||= calculate_ai_spend_projected
  end

  def ai_spend_this_month
    @ai_spend_this_month ||= calculate_ai_spend_this_month
  end

  def ai_spend_this_week
    @ai_spend_this_week ||= calculate_ai_spend_this_week
  end

  def ai_spend_today
    @ai_spend_today ||= calculate_ai_spend_today
  end

  def ai_spend_total
    @ai_spend_total ||= calculate_ai_spend_total
  end

  def budget_percentage_used
    @budget_percentage_used ||= calculate_budget_percentage_used
  end

  def budget_remaining
    @budget_remaining ||= calculate_budget_remaining
  end

  def budget_status
    @budget_status ||= calculate_budget_status
  end

  def comparisons_count
    @comparisons_count ||= Comparison.count
  end

  def repositories_count
    @repositories_count ||= Repository.count
  end

  def spend_by_model
    @spend_by_model ||= AiCost.by_model_breakdown(AiCost.this_month)
  end

  def spend_by_user
    @spend_by_user ||= AiCost.by_user_breakdown(AiCost.this_month, limit: 10)
  end

  def total_views
    @total_views ||= calculate_total_views
  end

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  private

  def calculate_ai_spend_projected
    days = Time.current.day
    daily_average = days.zero? ? 0 : (ai_spend_this_month / days)
    days_in_month = Time.current.end_of_month.day
    daily_average * days_in_month
  end

  def calculate_ai_spend_this_month
    AiCost.this_month.sum(:total_cost_usd)
  end

  def calculate_ai_spend_this_week
    AiCost.this_week.sum(:total_cost_usd)
  end

  def calculate_ai_spend_today
    AiCost.spend_today
  end

  def calculate_ai_spend_total
    AiCost.total_spend
  end

  def calculate_budget_percentage_used
    (ai_spend_this_month / BUDGET_MONTHLY * 100).round(1)
  end

  def calculate_budget_remaining
    BUDGET_MONTHLY - ai_spend_this_month
  end

  def calculate_budget_status
    percentage = budget_percentage_used
    case percentage
    when 0...50 then :healthy
    when 50...75 then :warning
    when 75...90 then :critical
    else :exceeded
    end
  end

  def calculate_total_views
    Comparison.sum(:view_count)
  end
end
