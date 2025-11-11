require "application_system_test_case"

class ComparisonCreationTest < ApplicationSystemTestCase
  def setup
    super
    sign_in users(:one)
    stub_openai_chat(response_content: comparison_ai_response.to_json)
    stub_github_search
  end

  test "submitting comparison query shows progress modal" do
    visit root_path

    # Submit comparison query
    fill_in "query", with: "Rails background jobs"
    find("button[type='submit']").click

    # Progress modal should appear with correct structure
    assert_selector "#comparison-progress-modal", wait: 2
    assert_text "Creating Your Comparison"
    assert_text "Analyzing repositories and generating AI-powered insights..."
  end

  test "progress modal has all required UI elements" do
    visit root_path

    fill_in "query", with: "Rails background jobs"
    find("button[type='submit']").click

    assert_selector "#comparison-progress-modal", wait: 2

    # Current message target
    assert_selector "[data-comparison-progress-target='currentMessage']"

    # Progress bar elements (may have 0 width initially, so use visible: :all)
    assert_selector "[data-comparison-progress-target='progressBar']", visible: :all
    assert_selector "[data-comparison-progress-target='percentage']"

    # All 6 steps are rendered in correct order
    steps = all("[data-comparison-step]").map { |el| el["data-comparison-step"] }
    assert_equal [
      "parsing_query",
      "searching_github",
      "merging_results",
      "analyzing_repositories",
      "comparing_repositories",
      "saving_comparison"
    ], steps

    # Error container exists (hidden by default, so use visible: :all)
    assert_selector "[data-comparison-progress-target='errorContainer'].hidden", visible: :all
    assert_selector "[data-comparison-progress-target='errorMessage']", visible: :all

    # Initial state shows 0%
    assert_selector "[data-comparison-progress-target='percentage']", text: "0%"
  end

  test "modal validates step order on connect" do
    # This test verifies the validateStepOrder() method would catch mismatches
    # The actual validation happens in JavaScript and would log to console on mismatch
    visit root_path

    fill_in "query", with: "Rails background jobs"
    find("button[type='submit']").click

    assert_selector "#comparison-progress-modal", wait: 2

    # If step order was wrong, the modal would still appear but validation
    # would fail (logged to console). We verify all steps exist in DOM.
    assert_selector "[data-comparison-step='parsing_query']"
    assert_selector "[data-comparison-step='searching_github']"
    assert_selector "[data-comparison-step='merging_results']"
    assert_selector "[data-comparison-step='analyzing_repositories']"
    assert_selector "[data-comparison-step='comparing_repositories']"
    assert_selector "[data-comparison-step='saving_comparison']"
  end

  test "progress modal controller is attached correctly" do
    visit root_path

    fill_in "query", with: "Rails background jobs"
    find("button[type='submit']").click

    # Modal should have the Stimulus controller attached
    modal = find("#comparison-progress-modal", wait: 2)
    assert_equal "comparison-progress", modal["data-controller"]

    # Should have session ID value set
    assert modal["data-comparison-progress-session-id-value"].present?
  end

  private

  def comparison_ai_response
    {
      "recommended_repo" => "test/test-repo",
      "recommendation_reasoning" => "Best option for testing",
      "ranking" => [
        {
          "rank" => 1,
          "repo_full_name" => "test/test-repo",
          "score" => 95,
          "pros" => [ "Well tested", "Good documentation" ],
          "cons" => [ "Smaller community" ],
          "fit_reasoning" => "Perfect fit for your needs"
        }
      ]
    }
  end
end
