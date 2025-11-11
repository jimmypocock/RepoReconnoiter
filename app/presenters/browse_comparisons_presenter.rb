class BrowseComparisonsPresenter
  attr_reader :params

  def initialize(params)
    @params = params
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def comparisons
    @comparisons ||= build_comparisons_scope
  end

  def has_filters?
    params[:date].present? || params[:search].present?
  end

  def recent_comparisons
    @recent_comparisons ||= Comparison.includes(:categories).recent.limit(8)
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def build_comparisons_scope
    scope = Comparison.includes(:categories)
    scope = apply_date_filter(scope)
    scope = apply_search(scope)
    apply_sorting(scope)
  end

  def apply_date_filter(scope)
    case params[:date]
    when "week" then scope.this_week
    when "month" then scope.this_month
    else scope
    end
  end

  def apply_search(scope)
    params[:search].present? ? scope.search(params[:search]) : scope
  end

  def apply_sorting(scope)
    return scope if params[:search].present?

    params[:sort] == "popular" ? scope.popular : scope.recent
  end
end
