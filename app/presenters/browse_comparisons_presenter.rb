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
    params[:category].present? || params[:date].present? || params[:search].present?
  end

  def trending
    @trending ||= trending_comparisons
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def apply_filters(scope)
    scope = filter_by_category(scope)
    scope = filter_by_date(scope)
    scope = filter_by_search(scope)
    apply_sort(scope)
  end

  def apply_sort(scope)
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
    Comparison.all
  end

  def filter_by_category(scope)
    return scope unless params[:category].present?

    category = Category.find_by(slug: params[:category])
    return scope unless category

    scope.joins(:categories).where(categories: { id: category.id })
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

    scope.where("user_query ILIKE ?", "%#{params[:search]}%")
  end

  def trending_comparisons
    Comparison.order(created_at: :desc)
              .limit(8)
  end
end
