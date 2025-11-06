class HomePagePresenter
  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Comparisons List
  def comparisons
    @comparisons ||= Comparison.for_homepage
  end

  # Stats (cached for performance)
  def stats
    @stats ||= Rails.cache.fetch("homepage_stats", expires_in: 10.minutes) do
      {
        repositories_count: Repository.count,
        comparisons_count: Comparison.count,
        total_views: Comparison.sum(:view_count),
        total_ai_cost: AiCost.sum(:total_cost_usd)
      }
    end
  end

  # Trending Comparisons
  def most_helpful_comparison
    @most_helpful_comparison ||= Comparison.order(view_count: :desc).first
  end

  def newest_comparison
    @newest_comparison ||= Comparison.order(created_at: :desc).first
  end

  def popular_this_week
    @popular_this_week ||= Comparison.where("created_at > ?", 7.days.ago).order(view_count: :desc).first
  end

  # Top Categories
  def top_architecture_patterns
    @top_architecture_patterns ||= Category.architecture_patterns
                                            .popular
                                            .limit(2)
                                            .includes(:repositories)
  end

  def top_maturity_levels
    @top_maturity_levels ||= Category.maturity_levels
                                      .popular
                                      .limit(2)
                                      .includes(:repositories)
  end

  def top_problem_domains
    @top_problem_domains ||= Category.problem_domains
                                      .popular
                                      .limit(2)
                                      .includes(:repositories)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Invalidate cached stats when data changes
    def invalidate_stats_cache
      Rails.cache.delete("homepage_stats")
    end
  end
end
