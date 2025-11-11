require "test_helper"

# Integration test for ComparisonCreator orchestration pipeline
# Tests the full flow: UserQueryParser → RepositoryFetcher → RepositoryComparer → Comparison
# Stubs only external APIs (OpenAI, GitHub), everything else runs for real
class ComparisonCreatorTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  #--------------------------------------
  # CACHE BEHAVIOR
  #--------------------------------------

  test "returns cached comparison when identical query exists" do
    query = "Ruby background processing library"

    # Create a cached comparison with identical query (perfect match)
    cached_comparison = Comparison.create!(
      user_query: query,
      normalized_query: Comparison.normalize_query_string(query),
      user: @user,
      repos_compared_count: 2,
      input_tokens: 1000,
      output_tokens: 500,
      model_used: "gpt-5",
      cost_usd: 0.015,
      created_at: 1.day.ago
    )

    result = ComparisonCreator.call(query: query, user: @user)

    assert_equal cached_comparison.id, result.record.id, "Should return cached comparison"
    refute result.newly_created, "Should not be newly created"
    assert_equal 1.0, result.similarity, "Similarity should be 1.0 for identical query"
  end
end
