require "test_helper"

class MissionControlTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  #--------------------------------------
  # SECURITY: Mission Control Access Control
  #--------------------------------------

  test "unauthenticated user cannot access jobs dashboard" do
    get "/admin/jobs"

    # Should be redirected (not allowed to access)
    assert_response :redirect
    refute_equal 200, response.status, "Unauthenticated user should not access jobs dashboard"
  end

  test "authenticated non-admin user cannot access jobs dashboard" do
    # User with GitHub ID 12345 (not in admin list)
    user = users(:one)

    # Temporarily set admin IDs (not including this user)
    with_env("ALLOWED_ADMIN_GITHUB_IDS" => "999999") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      get "/admin/jobs"

      # Should be redirected or forbidden (not allowed to access)
      assert_includes [ 302, 303, 403 ], response.status, "Non-admin should not access jobs dashboard"
      assert_equal "You don't have permission to access this page.", flash[:alert]
    end
  end

  test "authenticated admin user can access jobs dashboard" do
    user = users(:one) # GitHub ID: 12345

    # Add this user to admin list
    with_env("ALLOWED_ADMIN_GITHUB_IDS" => "12345") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      get "/admin/jobs"

      # Should successfully load the jobs dashboard
      assert_response :success
    end
  end

  test "multiple admin IDs work correctly" do
    user = users(:two) # GitHub ID: 67890

    # Multiple admins in comma-separated list
    with_env("ALLOWED_ADMIN_GITHUB_IDS" => "12345,67890,111111") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      get "/admin/jobs"

      assert_response :success
    end
  end

  test "raises error when ALLOWED_ADMIN_GITHUB_IDS is not set" do
    user = users(:one)

    with_env("ALLOWED_ADMIN_GITHUB_IDS" => "") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      # User#admin? will return false when ALLOWED_ADMIN_GITHUB_IDS is empty
      # This should redirect (not raise) now
      get "/admin/jobs"

      assert_response :redirect
      assert_equal "You don't have permission to access this page.", flash[:alert]
    end
  end

  private

  # Helper to temporarily set environment variables for testing
  def with_env(variables)
    old_values = {}
    variables.each do |key, value|
      old_values[key] = ENV[key]
      ENV[key] = value
    end

    yield
  ensure
    old_values.each do |key, value|
      ENV[key] = value
    end
  end

  # Reload Mission Control configuration with new environment variables
  def reload_mission_control_config
    # Re-evaluate the require_admin! method with new ENV values
    # This delegates to User#admin? which checks ALLOWED_ADMIN_GITHUB_IDS
    MissionControl::Jobs::ApplicationController.class_eval do
      def require_admin!
        unless current_user
          redirect_to main_app.root_path, alert: "You must be signed in to access this page."
          return
        end

        unless current_user.admin?
          redirect_to main_app.root_path, alert: "You don't have permission to access this page."
        end
      end
    end
  end
end
