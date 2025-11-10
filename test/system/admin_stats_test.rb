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
    assert_text "Repositories Indexed"
    assert_text "Comparisons Created"
    assert_text "Total Views"
    assert_text "Total AI Spend"
    assert_text "AI Spend Today"
  end

  test "stats display correct data" do
    sign_in @admin

    visit admin_stats_path

    stat_cards = all(".text-3xl.font-bold")
    assert_equal 5, stat_cards.count

    stat_cards.each do |card|
      assert_match(/\d+|\$\d+\.\d{2}/, card.text)
    end
  end
end
