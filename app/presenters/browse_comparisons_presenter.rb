class BrowseComparisonsPresenter
  attr_reader :params

  def initialize(params)
    @params = params
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def comparisons
    @comparisons ||= apply_filters(base_scope)
  end

  def has_filters?
    params[:date].present? || params[:search].present?
  end

  def trending
    @trending ||= trending_comparisons
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def apply_filters(scope)
    scope = filter_by_date(scope)
    scope = filter_by_search(scope)
    apply_sort(scope)
  end

  def apply_sort(scope)
    # If searching, use relevance scoring (don't override with manual sort)
    return scope if params[:search].present?

    case params[:sort]
    when "popular"
      scope.order(view_count: :desc)
    when "trending"
      scope.where("created_at > ?", 7.days.ago).order(view_count: :desc)
    else
      scope.order(created_at: :desc)
    end
  end

  def base_scope
    Comparison.includes(:categories)
  end

  def filter_by_date(scope)
    case params[:date]
    when "week"
      scope.where("comparisons.created_at > ?", 7.days.ago)
    when "month"
      scope.where("comparisons.created_at > ?", 30.days.ago)
    else
      scope
    end
  end

  def filter_by_search(scope)
    return scope unless params[:search].present?

    scope.search(params[:search])
  end

  def trending_comparisons
    Comparison.includes(:categories)
              .order(created_at: :desc)
              .limit(8)
  end
end
