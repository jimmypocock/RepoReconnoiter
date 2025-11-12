require "test_helper"

module Api
  module V1
    class ComparisonsControllerTest < ActionDispatch::IntegrationTest
      #--------------------------------------
      # INDEX ENDPOINT TESTS
      #--------------------------------------

      test "GET /api/v1/comparisons returns success" do
        get api_v1_comparisons_path, as: :json

        assert_response :success
        assert_equal "application/json; charset=utf-8", response.content_type
        assert_schema_conform
      end

      test "GET /api/v1/comparisons returns data and meta structure" do
        get api_v1_comparisons_path, as: :json

        json = JSON.parse(response.body)

        assert json.key?("data"), "Response should have 'data' key"
        assert json.key?("meta"), "Response should have 'meta' key"
        assert json["data"].is_a?(Array), "data should be an array"
        assert_schema_conform
      end

      test "GET /api/v1/comparisons returns pagination metadata" do
        get api_v1_comparisons_path, as: :json

        json = JSON.parse(response.body)
        pagination = json["meta"]["pagination"]

        assert pagination.key?("page")
        assert pagination.key?("per_page")
        assert pagination.key?("total_pages")
        assert pagination.key?("total_count")
        assert pagination.key?("next_page")
        assert pagination.key?("prev_page")
      end

      test "GET /api/v1/comparisons returns comparison attributes" do
        # Create a comparison with known data
        comparison = Comparison.create!(
          user_query: "Test query",
          normalized_query: "test query",
          technologies: "Rails, Ruby",
          repos_compared_count: 3
        )

        get api_v1_comparisons_path, as: :json

        json = JSON.parse(response.body)
        comparison_data = json["data"].find { |c| c["id"] == comparison.id }

        assert_not_nil comparison_data
        assert_equal "Test query", comparison_data["user_query"]
        assert_equal "test query", comparison_data["normalized_query"]
        assert_equal "Rails, Ruby", comparison_data["technologies"]
        assert_equal 3, comparison_data["repos_compared_count"]
        assert comparison_data.key?("created_at")
        assert comparison_data.key?("updated_at")
      end

      #--------------------------------------
      # PAGINATION TESTS
      #--------------------------------------

      test "GET /api/v1/comparisons respects per_page parameter" do
        get api_v1_comparisons_path, params: { per_page: 10 }, as: :json

        json = JSON.parse(response.body)
        # Should return 10 items or less if fewer exist
        assert_operator json["data"].size, :<=, 10
        assert_equal 10, json["meta"]["pagination"]["per_page"]
        assert_schema_conform
      end

      test "GET /api/v1/comparisons caps per_page at 100" do
        get api_v1_comparisons_path, params: { per_page: 500 }, as: :json

        json = JSON.parse(response.body)
        assert_equal 100, json["meta"]["pagination"]["per_page"]
      end

      test "GET /api/v1/comparisons handles page parameter" do
        # Ensure we have enough data for multiple pages
        total_count = Comparison.count
        skip "Need at least 11 comparisons for this test" if total_count < 11

        get api_v1_comparisons_path, params: { page: 2, per_page: 10 }, as: :json

        json = JSON.parse(response.body)
        assert_equal 2, json["meta"]["pagination"]["page"]
        # Page 2 should have items if total > 10
        assert_operator json["data"].size, :>, 0
      end

      #--------------------------------------
      # FILTERING TESTS
      #--------------------------------------

      test "GET /api/v1/comparisons filters by search parameter" do
        rails_comparison = Comparison.create!(
          user_query: "Rails background job library",
          normalized_query: "rails background job library",
          technologies: "Rails, Ruby",
          repos_compared_count: 1
        )

        python_comparison = Comparison.create!(
          user_query: "Python web framework",
          normalized_query: "python web framework",
          technologies: "Python",
          repos_compared_count: 1
        )

        get api_v1_comparisons_path, params: { search: "Rails" }, as: :json

        json = JSON.parse(response.body)
        ids = json["data"].map { |c| c["id"] }

        assert_includes ids, rails_comparison.id
        # Note: fuzzy search might include Python if it matches other fields
        assert_schema_conform
      end

      test "GET /api/v1/comparisons filters by date parameter" do
        recent = Comparison.create!(
          user_query: "Recent",
          normalized_query: "recent",
          repos_compared_count: 1,
          created_at: 3.days.ago
        )

        old = Comparison.create!(
          user_query: "Old",
          normalized_query: "old",
          repos_compared_count: 1,
          created_at: 10.days.ago
        )

        get api_v1_comparisons_path, params: { date: "week" }, as: :json

        json = JSON.parse(response.body)
        ids = json["data"].map { |c| c["id"] }

        assert_includes ids, recent.id
        refute_includes ids, old.id
      end

      #--------------------------------------
      # SORTING TESTS
      #--------------------------------------

      test "GET /api/v1/comparisons sorts by recent by default" do
        old = Comparison.create!(
          user_query: "Old",
          normalized_query: "old",
          repos_compared_count: 1,
          created_at: 5.days.ago
        )

        new = Comparison.create!(
          user_query: "New",
          normalized_query: "new",
          repos_compared_count: 1,
          created_at: 1.day.ago
        )

        get api_v1_comparisons_path, as: :json

        json = JSON.parse(response.body)

        # Find positions of our comparisons
        new_index = json["data"].index { |c| c["id"] == new.id }
        old_index = json["data"].index { |c| c["id"] == old.id }

        assert new_index < old_index, "Newer comparison should appear first"
      end

      test "GET /api/v1/comparisons sorts by popular" do
        unpopular = Comparison.create!(
          user_query: "Unpopular",
          normalized_query: "unpopular",
          repos_compared_count: 1,
          view_count: 5
        )

        popular = Comparison.create!(
          user_query: "Popular",
          normalized_query: "popular",
          repos_compared_count: 1,
          view_count: 100
        )

        get api_v1_comparisons_path, params: { sort: "popular" }, as: :json

        json = JSON.parse(response.body)

        # Find positions
        popular_index = json["data"].index { |c| c["id"] == popular.id }
        unpopular_index = json["data"].index { |c| c["id"] == unpopular.id }

        assert popular_index < unpopular_index, "Popular comparison should appear first"
        assert_schema_conform
      end

      #--------------------------------------
      # INCLUDES TESTS
      #--------------------------------------

      test "GET /api/v1/comparisons includes categories when loaded" do
        comparison = Comparison.create!(
          user_query: "Test",
          normalized_query: "test",
          repos_compared_count: 1
        )

        category = categories(:one)
        ComparisonCategory.create!(
          comparison: comparison,
          category: category,
          confidence_score: 0.95
        )

        get api_v1_comparisons_path, as: :json

        json = JSON.parse(response.body)
        comparison_data = json["data"].find { |c| c["id"] == comparison.id }

        assert comparison_data.key?("categories")
        assert comparison_data["categories"].is_a?(Array)
        assert_equal 1, comparison_data["categories"].size
        assert_equal category.id, comparison_data["categories"].first["id"]
        assert_schema_conform
      end

      test "GET /api/v1/comparisons includes repositories when loaded" do
        comparison = Comparison.create!(
          user_query: "Test",
          normalized_query: "test",
          repos_compared_count: 1
        )

        repo = repositories(:one)
        ComparisonRepository.create!(
          comparison: comparison,
          repository: repo,
          rank: 1,
          score: 95
        )

        get api_v1_comparisons_path, as: :json

        json = JSON.parse(response.body)
        comparison_data = json["data"].find { |c| c["id"] == comparison.id }

        assert comparison_data.key?("repositories")
        assert comparison_data["repositories"].is_a?(Array)
        assert_equal 1, comparison_data["repositories"].size
        assert_equal repo.id, comparison_data["repositories"].first["id"]
        assert_schema_conform
      end
    end
  end
end
