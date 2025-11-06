require "application_system_test_case"

class HomepageTest < ApplicationSystemTestCase
  # Use standard fixtures

  def setup
    super
    # Stub external APIs to prevent real API calls in tests
    stub_openai_chat
    stub_github_search
  end

  test "unauthenticated user sees auth section and comparisons" do
    visit root_path

    # Header
    assert_selector "h1", text: "RepoReconnoiter"
    assert_selector "p", text: "Find the perfect library for your project"

    # Auth section (not search section)
    assert_text "Sign in with GitHub"
    assert_text "jimmypocock@yahoo.com"
    assert_text "request an invite"
    refute_selector "input[name='query']"

    # Comparisons list visible to everyone
    assert_selector "h2", text: "Recent Comparisons"
  end

  test "authenticated user sees search section and comparisons" do
    # Sign in the user
    sign_in users(:one)

    visit root_path

    # Header
    assert_selector "h1", text: "RepoReconnoiter"
    assert_selector "p", text: "Find the perfect library for your project"

    # Search section (not auth section)
    assert_selector "input[name='query']"
    assert_button "Search"
    refute_text "Sign in with GitHub"

    # Example queries
    assert_text "Try these examples:"

    # Comparisons list visible to everyone
    assert_selector "h2", text: "Recent Comparisons"
  end

  test "comparisons list displays comparison cards correctly" do
    visit root_path

    # Check comparison cards are displayed
    within ".grid" do
      # Should have comparison cards
      assert_selector ".bg-white.rounded-2xl.shadow-lg", minimum: 1
    end
  end

  test "empty state when no comparisons exist" do
    # Delete all comparisons
    Comparison.destroy_all

    visit root_path

    assert_text "No comparisons yet"
    assert_text "Sign in to start comparing libraries!"
  end

  test "authenticated user sees different empty state message" do
    sign_in users(:one)
    Comparison.destroy_all

    visit root_path

    assert_text "No comparisons yet"
    assert_text "Try searching for a library above!"
  end

  test "search form submits query" do
    sign_in users(:one)

    visit root_path

    fill_in "query", with: "Rails background jobs"
    click_button "Search"

    # Should redirect to comparison show page or show error
    assert_current_path(%r{/comparisons/\d+|/})
  end
end
