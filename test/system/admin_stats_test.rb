require "application_system_test_case"

class AdminStatsTest < ApplicationSystemTestCase
  def setup
    super
    @admin = users(:one)
    ENV["ALLOWED_ADMIN_GITHUB_IDS"] = @admin.github_id.to_s
  end

  def teardown
    super
    ENV.delete("ALLOWED_ADMIN_GITHUB_IDS")
  end

  test "non-admin user cannot access stats page" do
    ENV["ALLOWED_ADMIN_GITHUB_IDS"] = "999999"
    sign_in users(:one)

    visit admin_stats_path

    assert_current_path root_path
    assert_text "Access denied."
  end

  test "unauthenticated user cannot access stats page" do
    ensure_unauthenticated

    visit admin_stats_path

    assert_current_path root_path
    assert_text "Please sign in with GitHub to continue."
  end

  test "admin user can access stats page" do
    sign_in @admin

    visit admin_stats_path

    assert_current_path admin_stats_path
    assert_selector "h1", text: "Admin Statistics"
    assert_text "System-wide metrics and usage data"

    # Usage section
    assert_selector "h2", text: "Usage"
    assert_text "Repositories Indexed"
    assert_text "Comparisons Created"
    assert_text "Total Views"

    # AI Spending section
    assert_selector "h2", text: "AI Spending"
    assert_text "Today"
    assert_text "This Week"
    assert_text "This Month"
    assert_text "Projected Monthly"
    assert_text "Total All Time"

    # Budget Status section
    assert_selector "h2", text: "Budget Status"
    assert_text "Status"
    assert_text "Budget Used"
    assert_text "Budget Remaining"
  end

  test "stats display correct data" do
    sign_in @admin

    visit admin_stats_path

    # We now have 11 stat cards (3 usage + 5 spending + 3 budget)
    stat_cards = all(".text-3xl.font-bold")
    assert_equal 11, stat_cards.count

    # Verify each card shows data (numbers or dollar amounts or status text)
    stat_cards.each do |card|
      assert_match(/\d+|\$\d+\.\d{2,4}|HEALTHY|WARNING|CRITICAL|EXCEEDED/i, card.text)
    end
  end
end
