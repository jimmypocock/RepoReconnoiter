require "test_helper"

class RepositoryComparerTest < ActiveSupport::TestCase
  def setup
    # Stub OpenAI chat for comparison
    stub_openai_chat(response_content: '{
      "recommended_repo": "sidekiq/sidekiq",
      "recommendation_reasoning": "Sidekiq is the most mature and widely adopted",
      "ranking": [
        {
          "repo_full_name": "sidekiq/sidekiq",
          "rank": 1,
          "score": 95,
          "pros": ["Mature", "Well documented"],
          "cons": ["Requires Redis"],
          "fit_reasoning": "Best overall choice"
        }
      ]
    }')

    # Stub OpenAI embeddings for CategoryMatcher
    stub_openai_embeddings

    @repo = repositories(:one)
  end

  #--------------------------------------
  # COMPARISON CREATION
  #--------------------------------------

  test "creates comparison record with proper associations" do
    comparer = RepositoryComparer.new
    comparison = comparer.compare_repositories(
      user_query: "Rails background job library",
      parsed_query: {
        tech_stack: "Rails",
        problem_domain: "Background Job Processing",
        constraints: [ "production ready" ],
        github_queries: [ "background job rails" ]
      },
      repositories: [
        {
          repository: @repo,
          quality_signals: { stars: 1000 }
        }
      ],
      user: nil
    )

    assert comparison.persisted?
    assert_equal "Rails background job library", comparison.user_query
    assert_equal "Rails", comparison.technologies
    assert_equal "Background Job Processing", comparison.problem_domains

    # Check repository association
    assert_equal 1, comparison.repositories.count
    assert_includes comparison.repositories, @repo

    # Check category association
    assert_operator comparison.categories.count, :>=, 1
  end
end
