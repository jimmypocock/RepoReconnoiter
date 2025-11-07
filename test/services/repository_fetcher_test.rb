require "test_helper"

class RepositoryFetcherTest < ActiveSupport::TestCase
  def setup
    stub_openai_chat(response_content: '{
      "categories": [
        {"name": "Background Jobs", "slug": "background-jobs", "category_type": "problem_domain", "confidence": 0.95}
      ],
      "summary": "Test summary",
      "use_cases": "Test use cases"
    }')
    stub_github_search
  end

  #--------------------------------------
  # ANALYSIS: Repository Analysis During Fetch
  #--------------------------------------

  test "fetch_and_prepare calls analyzer.analyze not analyze_repository" do
    fetcher = RepositoryFetcher.new

    # This test ensures we're calling the correct method name
    # The bug was calling analyzer.analyze_repository which doesn't exist
    # Should call analyzer.analyze instead

    # Should complete without NoMethodError
    assert_nothing_raised do
      result = fetcher.fetch_and_prepare(
        github_queries: ["test query"],
        limit: 5
      )

      # Basic sanity checks
      assert_kind_of Hash, result
      assert result.key?(:top_repositories)
      assert result.key?(:other_repositories)
    end
  end

  test "fetch_and_prepare returns structured data" do
    fetcher = RepositoryFetcher.new

    result = fetcher.fetch_and_prepare(
      github_queries: ["test query"],
      limit: 5
    )

    # Check structure
    assert_kind_of Array, result[:top_repositories]
    assert_kind_of Array, result[:other_repositories]
    assert_kind_of Integer, result[:total_found]
    assert_kind_of Integer, result[:queries_executed]
  end
end
