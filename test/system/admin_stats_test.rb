require "application_system_test_case"

class AdminStatsTest < ApplicationSystemTestCase
  def setup
    super
    # Set admin user for tests
    @admin = users(:one)
    ENV["MISSION_CONTROL_ADMIN_IDS"] = @admin.github_id.to_s
  end

  def teardown
    super
    ENV.delete("MISSION_CONTROL_ADMIN_IDS")
  end

  test "non-admin user cannot access stats page" do
    # Sign in as regular user (not admin)
    ENV["MISSION_CONTROL_ADMIN_IDS"] = "999999" # Different ID
    sign_in users(:one)

    visit admin_stats_path

    # Should be redirected to root
    assert_current_path root_path
    assert_text "Access denied."
  end

  test "unauthenticated user cannot access stats page" do
    ensure_unauthenticated

    visit admin_stats_path

    # Should be redirected to root
    assert_current_path root_path
    assert_text "Please sign in with GitHub to continue."
  end

  test "admin user can access stats page" do
    sign_in @admin

    visit admin_stats_path

    # Page loads successfully
    assert_current_path admin_stats_path

    # Header
    assert_selector "h1", text: "Admin Statistics"
    assert_text "System-wide metrics and usage data"

    # All 5 stat cards are present
    assert_text "Repositories Indexed"
    assert_text "Comparisons Created"
    assert_text "Total Views"
    assert_text "Total AI Spend"
    assert_text "AI Spend Today"
  end

  test "stats display correct data" do
    sign_in @admin

    visit admin_stats_path

    # Check that numeric values are displayed (should be 0 or more)
    stat_cards = all(".text-3xl.font-bold")
    assert_equal 5, stat_cards.count

    # Each stat should have a number or dollar amount
    stat_cards.each do |card|
      assert_match(/\d+|\$\d+\.\d{2}/, card.text)
    end
  end
end
