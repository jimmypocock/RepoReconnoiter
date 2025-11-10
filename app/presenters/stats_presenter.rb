class StatsPresenter
  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def ai_spend_today
    @ai_spend_today ||= calculate_ai_spend_today
  end

  def ai_spend_total
    @ai_spend_total ||= calculate_ai_spend_total
  end

  def comparisons_count
    @comparisons_count ||= Comparison.count
  end

  def repositories_count
    @repositories_count ||= Repository.count
  end

  def total_views
    @total_views ||= calculate_total_views
  end

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  private

  def calculate_ai_spend_today
    AiCost.spend_today
  end

  def calculate_ai_spend_total
    AiCost.total_spend
  end

  def calculate_total_views
    Comparison.sum(:view_count)
  end
end
