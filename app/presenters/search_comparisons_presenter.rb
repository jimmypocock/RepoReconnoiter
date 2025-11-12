class SearchComparisonsPresenter
  attr_reader :params

  def initialize(params)
    @params = params || {}
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

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def build_comparisons_scope
    scope = Comparison.includes(:categories, :repositories, comparison_repositories: :repository)
    scope = apply_date_filter(scope)
    scope = apply_search(scope)
    apply_sorting(scope)
  end

  def apply_date_filter(scope)
    case params[:date]
    when "week" then scope.past_7_days
    when "month" then scope.past_30_days
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
