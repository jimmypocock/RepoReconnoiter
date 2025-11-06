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

    # Homepage sections
    assert_text "Trending Comparisons"
    assert_text "Browse by Category"
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

    # Homepage sections
    assert_text "Trending Comparisons"
    assert_text "Browse by Category"
  end

  test "stats bar displays correctly" do
    visit root_path

    # Public stats visible to everyone
    assert_text "Repositories Indexed"
    assert_text "Comparisons Created"

    # Admin stats not visible to unauthenticated users
    refute_text "Total Views"
    refute_text "Total AI Spend"
  end

  test "trending section displays when comparisons exist" do
    visit root_path

    # Trending section header
    assert_selector "h2", text: "Trending Comparisons"

    # Should show trending cards if comparisons exist
    if Comparison.any?
      # Check for at least one trending card (text is uppercase in the view)
      assert_text /MOST HELPFUL/i
    end
  end

  test "browse categories section displays correctly" do
    # Create some categories with repositories
    problem_domain = Category.create!(
      name: "Test Problem Domain",
      slug: "test-problem-domain",
      category_type: "problem_domain",
      repositories_count: 5
    )

    visit root_path

    # Browse categories header
    assert_selector "h2", text: "Browse by Category"

    # Category type headers
    assert_text "Problem Domains"
    assert_text "Architecture Patterns"
    assert_text "Maturity Levels"
  end

  test "comparisons list displays comparison cards correctly" do
    visit root_path

    # Check comparison cards are displayed (look for specific comparison card class)
    assert_selector ".bg-white.rounded-2xl.shadow-lg", minimum: 1
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
