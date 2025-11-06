require "test_helper"

class HomePagePresenterTest < ActiveSupport::TestCase
  def setup
    @presenter = HomePagePresenter.new
  end

  #--------------------------------------
  # Comparisons
  #--------------------------------------

  test "comparisons returns homepage comparisons" do
    comparisons = @presenter.comparisons

    assert_instance_of Array, comparisons
    # Should delegate to Comparison.for_homepage
    assert_equal Comparison.for_homepage.map(&:id).sort, comparisons.map(&:id).sort
  end

  #--------------------------------------
  # Stats (Cached)
  #--------------------------------------

  test "stats returns hash with correct keys" do
    stats = @presenter.stats

    assert_kind_of Hash, stats
    assert_includes stats.keys, :repositories_count
    assert_includes stats.keys, :comparisons_count
    assert_includes stats.keys, :total_views
    assert_includes stats.keys, :total_ai_cost
  end

  test "stats returns correct counts" do
    # Clear cache to ensure fresh data
    Rails.cache.delete("homepage_stats")

    stats = @presenter.stats

    assert_equal Repository.count, stats[:repositories_count]
    assert_equal Comparison.count, stats[:comparisons_count]
    assert_equal Comparison.sum(:view_count), stats[:total_views]
  end

  test "stats caches result for 10 minutes" do
    # Clear cache
    Rails.cache.delete("homepage_stats")

    # First call - should cache
    first_stats = @presenter.stats

    # Create new data
    Repository.create!(
      github_id: 999999,
      node_id: "test",
      full_name: "test/repo",
      name: "repo",
      html_url: "https://github.com/test/repo"
    )

    # Second call - should return cached value (not updated count)
    second_stats = @presenter.stats

    assert_equal first_stats[:repositories_count], second_stats[:repositories_count]
  end

  test "invalidate_stats_cache clears cached stats" do
    # Prime the cache
    @presenter.stats

    # Invalidate
    HomePagePresenter.invalidate_stats_cache

    # Should be removed from cache
    refute Rails.cache.exist?("homepage_stats")
  end

  #--------------------------------------
  # Trending Comparisons
  #--------------------------------------

  test "most_helpful_comparison returns comparison with highest view count" do
    # Create comparisons with different view counts
    low_views = Comparison.create!(
      user_query: "low views",
      normalized_query: "low views",
      repos_compared_count: 1,
      view_count: 5
    )

    high_views = Comparison.create!(
      user_query: "high views",
      normalized_query: "high views",
      repos_compared_count: 1,
      view_count: 100
    )

    result = @presenter.most_helpful_comparison

    assert_equal high_views.id, result.id
  end

  test "newest_comparison returns most recently created comparison" do
    # Clear existing comparisons to avoid fixture interference
    Comparison.destroy_all

    old = Comparison.create!(
      user_query: "old",
      normalized_query: "old",
      repos_compared_count: 1,
      created_at: 2.days.ago
    )

    recent = Comparison.create!(
      user_query: "recent",
      normalized_query: "recent",
      repos_compared_count: 1,
      created_at: 1.hour.ago
    )

    result = @presenter.newest_comparison

    assert_equal recent.id, result.id
  end

  test "popular_this_week returns most viewed comparison from last 7 days" do
    # Old comparison with high views (should be excluded)
    old_popular = Comparison.create!(
      user_query: "old popular",
      normalized_query: "old popular",
      repos_compared_count: 1,
      view_count: 500,
      created_at: 10.days.ago
    )

    # Recent comparison with moderate views (should be returned)
    recent_popular = Comparison.create!(
      user_query: "recent popular",
      normalized_query: "recent popular",
      repos_compared_count: 1,
      view_count: 50,
      created_at: 3.days.ago
    )

    result = @presenter.popular_this_week

    assert_equal recent_popular.id, result.id
  end

  test "popular_this_week returns nil when no comparisons in last 7 days" do
    # Delete all recent comparisons
    Comparison.where("created_at > ?", 7.days.ago).destroy_all

    result = @presenter.popular_this_week

    assert_nil result
  end

  #--------------------------------------
  # Top Categories
  #--------------------------------------

  test "top_problem_domains returns 2 most popular problem domain categories" do
    # Create problem domain categories
    3.times do |i|
      Category.create!(
        name: "Problem Domain #{i}",
        slug: "problem-domain-#{i}",
        category_type: "problem_domain",
        repositories_count: i * 10
      )
    end

    result = @presenter.top_problem_domains

    assert_equal 2, result.size
    assert_equal "problem_domain", result.first.category_type
    # Should be ordered by repositories_count DESC
    assert_operator result.first.repositories_count, :>=, result.last.repositories_count
  end

  test "top_architecture_patterns returns 2 most popular architecture pattern categories" do
    # Create architecture pattern categories
    3.times do |i|
      Category.create!(
        name: "Architecture Pattern #{i}",
        slug: "architecture-pattern-#{i}",
        category_type: "architecture_pattern",
        repositories_count: i * 10
      )
    end

    result = @presenter.top_architecture_patterns

    assert_equal 2, result.size
    assert_equal "architecture_pattern", result.first.category_type
  end

  test "top_maturity_levels returns 2 most popular maturity level categories" do
    # Create maturity level categories
    3.times do |i|
      Category.create!(
        name: "Maturity Level #{i}",
        slug: "maturity-level-#{i}",
        category_type: "maturity",
        repositories_count: i * 10
      )
    end

    result = @presenter.top_maturity_levels

    assert_equal 2, result.size
    assert_equal "maturity", result.first.category_type
  end
end
