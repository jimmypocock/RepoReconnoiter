require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should redirect to login when not authenticated" do
    get profile_url
    assert_redirected_to root_path
  end

  test "should show profile page when authenticated" do
    sign_in @user
    get profile_url
    assert_response :success
    assert_select "h1", text: /#{@user.github_name || @user.github_username}/
  end

  test "should display usage stats" do
    sign_in @user
    get profile_url
    assert_response :success
    assert_select "h2", text: "Usage Stats"
    # Should show comparisons this month
    assert_match /Comparisons This Month/, response.body
    # Should show remaining limits
    assert_match /Comparisons Remaining Today/, response.body
  end

  test "should show comparisons list" do
    sign_in @user
    get profile_url
    assert_response :success
    assert_select "h2", text: "My Comparisons"
  end

  test "should show analyses list" do
    sign_in @user
    get profile_url
    assert_response :success
    assert_select "h2", text: "My Deep Analyses"
  end

  test "should show account settings" do
    sign_in @user
    get profile_url
    assert_response :success
    assert_select "h2", text: "Account Settings"
    assert_select "form[action=?]", profile_path
  end

  test "should delete account when authenticated" do
    sign_in @user

    assert_difference("User.where(deleted_at: nil).count", -1) do
      delete profile_url
    end

    assert_redirected_to root_url
    assert_equal "Your account has been deleted.", flash[:notice]

    @user.reload
    assert_not_nil @user.deleted_at
  end
end
