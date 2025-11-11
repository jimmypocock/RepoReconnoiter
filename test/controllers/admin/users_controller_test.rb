require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @non_admin = users(:two)
    @whitelisted_user = whitelisted_users(:one)
    # Set admin GitHub ID for testing
    ENV["ALLOWED_ADMIN_GITHUB_IDS"] = @admin.github_id.to_s
  end

  teardown do
    ENV.delete("ALLOWED_ADMIN_GITHUB_IDS")
  end

  test "should redirect non-authenticated users to login" do
    get admin_users_url
    assert_redirected_to root_path
  end

  test "should deny access to non-admin users" do
    sign_in @non_admin
    get admin_users_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end

  test "should show whitelist management page for admins" do
    sign_in @admin
    get admin_users_url
    assert_response :success
    assert_select "h1", text: "Whitelist Management"
  end

  test "should display add user form" do
    sign_in @admin
    get admin_users_url
    assert_response :success
    assert_select "form[action=?]", admin_users_path
    assert_select "input[name='whitelisted_user[github_id]']"
    assert_select "input[name='whitelisted_user[github_username]']"
  end

  test "should display whitelisted users table" do
    sign_in @admin
    get admin_users_url
    assert_response :success
    assert_select "table"
    assert_select "th", text: "User"
    assert_select "th", text: "GitHub ID"
  end

  test "should create whitelisted user" do
    sign_in @admin

    assert_difference("WhitelistedUser.count", 1) do
      post admin_users_url, params: {
        whitelisted_user: {
          github_id: 999888,
          github_username: "newuser",
          email: "newuser@example.com",
          notes: "Test user"
        }
      }
    end

    assert_redirected_to admin_users_url
    assert_equal "User newuser has been whitelisted.", flash[:notice]
  end

  test "should not create whitelisted user with invalid data" do
    sign_in @admin

    assert_no_difference("WhitelistedUser.count") do
      post admin_users_url, params: {
        whitelisted_user: {
          github_id: nil,
          github_username: ""
        }
      }
    end

    assert_redirected_to admin_users_url
    assert_match /Error/, flash[:alert]
  end

  test "should delete whitelisted user" do
    sign_in @admin

    # Use whitelisted user with no associated User record (can be deleted)
    user_to_delete = whitelisted_users(:three)

    assert_difference("WhitelistedUser.count", -1) do
      delete admin_user_url(user_to_delete)
    end

    assert_redirected_to admin_users_url
    assert_match /removed from whitelist/, flash[:notice]
  end

  test "should filter by search term" do
    sign_in @admin
    get admin_users_url, params: { search: @whitelisted_user.github_username }
    assert_response :success
    assert_match @whitelisted_user.github_username, response.body
  end

  test "should filter by admin status" do
    sign_in @admin
    get admin_users_url, params: { filter: "admins" }
    assert_response :success
    # Should show admin users
  end
end
