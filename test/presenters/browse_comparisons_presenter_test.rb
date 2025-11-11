require "test_helper"

class BrowseComparisonsPresenterTest < ActiveSupport::TestCase
  #--------------------------------------
  # SEARCH INTEGRATION
  #--------------------------------------

  test "search preserves relevance scoring order" do
    # Create comparisons with different relevance to "rails"
    high_relevance = create_comparison("Rails background job library")
    high_relevance.update!(technologies: "Rails, Ruby")

    low_relevance = create_comparison("Background job library")
    low_relevance.update!(technologies: "Python")

    presenter = BrowseComparisonsPresenter.new(search: "rails")
    results = presenter.comparisons.to_a

    # High relevance should be first
    assert_equal high_relevance.id, results.first.id
  end

  test "search does not override with manual sort" do
    old_rails = create_comparison("Rails library xyz", created_at: 2.days.ago)
    old_rails.update!(technologies: "Rails")

    new_python = create_comparison("Python library xyz", created_at: 1.day.ago)

    presenter = BrowseComparisonsPresenter.new(search: "rails xyz", sort: "newest")
    results = presenter.comparisons.to_a

    # Should use relevance (old Rails match), not created_at DESC (new Python)
    assert_equal old_rails.id, results.first.id, "Search should preserve relevance over manual sort"
  end

  #--------------------------------------
  # DATE FILTERING
  #--------------------------------------

  test "filters by week" do
    recent = create_comparison("Recent", created_at: 3.days.ago)
    old = create_comparison("Old", created_at: 10.days.ago)

    presenter = BrowseComparisonsPresenter.new(date: "week")

    assert_includes presenter.comparisons, recent
    refute_includes presenter.comparisons, old
  end

  test "filters by month" do
    recent = create_comparison("Recent", created_at: 20.days.ago)
    old = create_comparison("Old", created_at: 40.days.ago)

    presenter = BrowseComparisonsPresenter.new(date: "month")

    assert_includes presenter.comparisons, recent
    refute_includes presenter.comparisons, old
  end

  #--------------------------------------
  # SORTING
  #--------------------------------------

  test "sorts by newest (created_at DESC)" do
    old = create_comparison("Old unique xyz", created_at: 2.days.ago)
    new = create_comparison("New unique xyz", created_at: 1.hour.ago)

    presenter = BrowseComparisonsPresenter.new(sort: "newest")
    results = presenter.comparisons.to_a

    # Find our test records in results
    new_index = results.index { |c| c.id == new.id }
    old_index = results.index { |c| c.id == old.id }

    assert new_index < old_index, "Newer comparison should appear before older one"
  end

  test "sorts by popular (view_count DESC)" do
    unpopular = create_comparison("Unpopular")
    unpopular.update!(view_count: 5)

    popular = create_comparison("Popular")
    popular.update!(view_count: 100)

    presenter = BrowseComparisonsPresenter.new(sort: "popular")
    results = presenter.comparisons.to_a

    assert_equal popular.id, results.first.id
  end

  test "sorts by trending (recent + view_count)" do
    old_popular = create_comparison("Old Popular unique xyz", created_at: 10.days.ago)
    old_popular.update!(view_count: 100)

    recent_popular = create_comparison("Recent Popular unique xyz", created_at: 2.days.ago)
    recent_popular.update!(view_count: 50)

    presenter = BrowseComparisonsPresenter.new(sort: "trending")
    results = presenter.comparisons.to_a

    # Find our test records in results
    recent_index = results.index { |c| c.id == recent_popular.id }
    old_index = results.index { |c| c.id == old_popular.id }

    assert recent_index < old_index, "Recent popular should rank higher than old popular in trending"
  end

  #--------------------------------------
  # FILTER DETECTION
  #--------------------------------------

  test "has_filters? returns true when search present" do
    presenter = BrowseComparisonsPresenter.new(search: "rails")
    assert presenter.has_filters?
  end

  test "has_filters? returns true when date present" do
    presenter = BrowseComparisonsPresenter.new(date: "week")
    assert presenter.has_filters?
  end

  test "has_filters? returns false when no filters" do
    presenter = BrowseComparisonsPresenter.new({})
    refute presenter.has_filters?
  end

  private

  def create_comparison(query, created_at: Time.current)
    Comparison.create!(
      user_query: query,
      normalized_query: Comparison.normalize_query_string(query),
      repos_compared_count: 3,
      created_at: created_at,
      view_count: 0
    )
  end
end
