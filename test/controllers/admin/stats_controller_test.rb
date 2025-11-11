require "test_helper"

class Admin::StatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @non_admin = users(:two)
    # Set admin GitHub ID for testing
    ENV["ALLOWED_ADMIN_GITHUB_IDS"] = @admin.github_id.to_s
  end

  teardown do
    ENV.delete("ALLOWED_ADMIN_GITHUB_IDS")
  end

  test "should redirect non-authenticated users to login" do
    get admin_stats_url
    assert_redirected_to root_path
  end

  test "should deny access to non-admin users" do
    sign_in @non_admin
    get admin_stats_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end

  test "should show admin stats page" do
    sign_in @admin
    get admin_stats_url
    assert_response :success
    assert_select "h1", text: "Admin Statistics"
  end

  test "should display usage stats section" do
    sign_in @admin
    get admin_stats_url
    assert_response :success
    assert_select "h2", text: "Usage"
    assert_match /Repositories Indexed/, response.body
    assert_match /Comparisons Created/, response.body
  end

  test "should display AI spending stats" do
    sign_in @admin
    get admin_stats_url
    assert_response :success
    assert_select "h2", text: "AI Spending"
    assert_match /Today/, response.body
    assert_match /This Week/, response.body
    assert_match /This Month/, response.body
  end

  test "should display budget status" do
    sign_in @admin
    get admin_stats_url
    assert_response :success
    assert_select "h2", text: "Budget Status"
    assert_match /Budget Used/, response.body
    assert_match /Budget Remaining/, response.body
  end

  test "should display spend by model section" do
    sign_in @admin
    get admin_stats_url
    assert_response :success
    assert_select "h2", text: "Spend by Model (This Month)"
  end

  test "should display spend by user section" do
    sign_in @admin
    get admin_stats_url
    assert_response :success
    assert_select "h2", text: "Top Users by Spend (This Month)"
  end
end
