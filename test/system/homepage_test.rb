require "application_system_test_case"

class HomepageTest < ApplicationSystemTestCase
  # Use standard fixtures

  def setup
    super
    # Stub external APIs to prevent real API calls in tests
    stub_openai_chat
    stub_github_search
  end

  test "unauthenticated user sees navigation and comparisons" do
    ensure_unauthenticated

    visit root_path

    # Navigation elements
    assert_text "Repo Reconnoiter"
    assert_link "Join the Waitlist"
    assert_button "Sign in with GitHub"

    # Filter bar exists (visible to all users)
    assert_selector "input[name='search']"
    assert_selector "select[name='sort']"
  end

  test "authenticated user sees navigation and comparisons" do
    # Sign in the user
    sign_in users(:one)

    visit root_path

    # Navigation shows user menu (not waitlist/sign in)
    assert_text "Repo Reconnoiter"
    refute_link "Join the Waitlist"
    refute_button "Sign in with GitHub"

    # Filter bar exists
    assert_selector "input[name='search']"
    assert_selector "select[name='sort']"
  end

  test "recent searches section displays when comparisons exist" do
    visit root_path

    # Recent searches section header
    assert_text "Recent Searches"

    # Should show recent searches in compact list format if comparisons exist
    if Comparison.any?
      # Check for list container with dividers
      assert_selector ".divide-y"
    end
  end

  test "comparisons list displays comparison cards correctly" do
    visit root_path

    # Check comparison cards are displayed (look for specific comparison card class)
    assert_selector ".bg-white.rounded-xl.shadow-sm", minimum: 1
  end

  test "empty state when no comparisons exist" do
    ensure_unauthenticated
    Comparison.destroy_all

    visit root_path

    assert_text "No comparisons found"
    assert_text "Try adjusting your filters or search terms"
    assert_link "Clear Filters"
  end

  test "authenticated user sees same empty state message" do
    sign_in users(:one)
    Comparison.destroy_all

    visit root_path

    assert_text "No comparisons found"
    assert_text "Try adjusting your filters or search terms"
    assert_link "Clear Filters"
  end
end
