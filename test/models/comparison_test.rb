require "test_helper"

class ComparisonTest < ActiveSupport::TestCase
  #--------------------------------------
  # COST CONTROL: Fuzzy Cache Matching
  #--------------------------------------

  test "find_similar_cached returns exact match" do
    # Create a cached comparison
    comparison = create_comparison("rails background jobs", created_at: 1.day.ago)

    result, score = Comparison.find_similar_cached("rails background jobs")

    assert_equal comparison.id, result.id
    assert_operator score, :>, 0.9, "Exact match should have very high similarity score"
  end

  test "find_similar_cached returns nil for dissimilar query" do
    # Create a cached comparison
    create_comparison("rails background jobs", created_at: 1.day.ago)

    # Query is completely different
    result, score = Comparison.find_similar_cached("python machine learning")

    assert_nil result
    assert_equal 0.0, score
  end

  test "find_similar_cached respects cache TTL" do
    # Create comparison older than CACHE_TTL_DAYS
    old_comparison = create_comparison("rails background jobs", created_at: 8.days.ago)

    result, score = Comparison.find_similar_cached("rails background jobs")

    # Should return nil because comparison is stale
    assert_nil result
    assert_equal 0.0, score
  end

  test "find_similar_cached returns most similar result when multiple matches" do
    # Create two similar comparisons
    exact_match = create_comparison("rails background jobs", created_at: 2.days.ago)
    partial_match = create_comparison("rails background processing system", created_at: 1.day.ago)

    result, score = Comparison.find_similar_cached("rails background jobs")

    # Should return the exact match (higher similarity)
    assert_equal exact_match.id, result.id
    assert_operator score, :>, 0.9, "Should return highest similarity match"
  end

  test "find_similar_cached normalizes query (case insensitive)" do
    comparison = create_comparison("Rails Background Jobs", created_at: 1.day.ago)

    # Query with different case
    result, score = Comparison.find_similar_cached("RAILS BACKGROUND JOBS")

    assert_equal comparison.id, result.id
    assert_operator score, :>, 0.9
  end

  test "find_similar_cached normalizes query (whitespace)" do
    comparison = create_comparison("rails background jobs", created_at: 1.day.ago)

    # Query with extra whitespace
    result, score = Comparison.find_similar_cached("  rails   background    jobs  ")

    assert_equal comparison.id, result.id
    assert_operator score, :>, 0.9
  end

  test "normalize_query_string handles whitespace and case correctly" do
    query = "  Rails   Background   JOBS  "
    normalized = Comparison.normalize_query_string(query)

    assert_equal "rails background jobs", normalized
  end

  #--------------------------------------
  # SEARCH: Comprehensive Multi-Field Search
  #--------------------------------------

  test "search finds by user_query" do
    comparison = create_comparison("Rails background job library")

    results = Comparison.search("background")

    assert_includes results, comparison
  end

  test "search finds by technologies" do
    comparison = create_comparison("job library")
    comparison.update!(technologies: "Rails, Ruby")

    results = Comparison.search("ruby")

    assert_includes results, comparison
  end

  test "search finds by problem_domains" do
    comparison = create_comparison("job library")
    comparison.update!(problem_domains: "Background Job Processing")

    results = Comparison.search("processing")

    assert_includes results, comparison
  end

  test "search finds by associated category name" do
    comparison = create_comparison("job library")
    category = categories(:one) # "Background Jobs" category
    comparison.comparison_categories.create!(category: category, assigned_by: "ai")

    results = Comparison.search("background")

    assert_includes results, comparison
  end

  test "search is case insensitive" do
    comparison = create_comparison("Rails library")
    comparison.update!(technologies: "Rails, Ruby")

    [ "RAILS", "rails", "RaIlS" ].each do |search_term|
      results = Comparison.search(search_term)
      assert_includes results, comparison, "Should find comparison with search term: #{search_term}"
    end
  end

  test "search handles partial matches" do
    comparison = create_comparison("authentication library")
    comparison.update!(problem_domains: "Authentication")

    results = Comparison.search("auth")

    assert_includes results, comparison
  end

  test "search returns empty for blank search term" do
    create_comparison("Rails library")

    results = Comparison.search("")

    assert_equal Comparison.count, results.count
  end

  test "search returns empty for nil search term" do
    create_comparison("Rails library")

    results = Comparison.search(nil)

    assert_equal Comparison.count, results.count
  end

  test "search finds across multiple fields" do
    comparison = create_comparison("best job library")
    comparison.update!(
      technologies: "Rails, Ruby",
      problem_domains: "Background Job Processing"
    )

    # Should find it via any of these fields
    [ "job", "rails", "background", "processing" ].each do |search_term|
      results = Comparison.search(search_term)
      assert_includes results, comparison, "Should find via: #{search_term}"
    end
  end

  test "search does not match unrelated comparisons" do
    rails_comparison = create_comparison("Rails background job library")
    rails_comparison.update!(technologies: "Rails, Ruby", problem_domains: "Background Jobs")

    python_comparison = create_comparison("Python machine learning library")
    python_comparison.update!(technologies: "Python", problem_domains: "Machine Learning")

    results = Comparison.search("rails")

    assert_includes results, rails_comparison
    refute_includes results, python_comparison
  end

  private

  def create_comparison(query, created_at: Time.current)
    Comparison.create!(
      user_query: query,
      normalized_query: Comparison.normalize_query_string(query),
      repos_compared_count: 3,
      created_at: created_at
    )
  end
end
