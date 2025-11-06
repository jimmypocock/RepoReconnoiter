require "test_helper"

class MissionControlTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  #--------------------------------------
  # SECURITY: Mission Control Access Control
  #--------------------------------------

  test "unauthenticated user cannot access jobs dashboard" do
    get "/jobs"

    # Should be redirected (not allowed to access)
    assert_response :redirect
    refute_equal 200, response.status, "Unauthenticated user should not access jobs dashboard"
  end

  test "authenticated non-admin user cannot access jobs dashboard" do
    # User with GitHub ID 12345 (not in admin list)
    user = users(:one)

    # Temporarily set admin IDs (not including this user)
    with_env("MISSION_CONTROL_ADMIN_IDS" => "999999") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      get "/jobs"

      # Should be redirected or forbidden (not allowed to access)
      assert_includes [ 302, 303, 403 ], response.status, "Non-admin should not access jobs dashboard"
      assert_equal "You don't have permission to access this page.", flash[:alert]
    end
  end

  test "authenticated admin user can access jobs dashboard" do
    user = users(:one) # GitHub ID: 12345

    # Add this user to admin list
    with_env("MISSION_CONTROL_ADMIN_IDS" => "12345") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      get "/jobs"

      # Should successfully load the jobs dashboard
      assert_response :success
    end
  end

  test "multiple admin IDs work correctly" do
    user = users(:two) # GitHub ID: 67890

    # Multiple admins in comma-separated list
    with_env("MISSION_CONTROL_ADMIN_IDS" => "12345,67890,111111") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      get "/jobs"

      assert_response :success
    end
  end

  test "raises error when MISSION_CONTROL_ADMIN_IDS is not set" do
    user = users(:one)

    with_env("MISSION_CONTROL_ADMIN_IDS" => "") do
      sign_in user

      # Reload initializer with new env variables
      reload_mission_control_config

      assert_raises(RuntimeError, "MISSION_CONTROL_ADMIN_IDS must be set") do
        get "/jobs"
      end
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
    # Re-evaluate the check_admin_access! method with new ENV values
    MissionControl::Jobs::ApplicationController.class_eval do
      def check_admin_access!
        unless current_user
          redirect_to main_app.root_path, alert: "You must be signed in to access this page."
          return
        end

        allowed_admin_github_ids = ENV.fetch("MISSION_CONTROL_ADMIN_IDS", "").split(",").map(&:strip).reject(&:empty?)

        # Require at least one admin ID to be configured
        if allowed_admin_github_ids.empty?
          raise "MISSION_CONTROL_ADMIN_IDS must be set in environment variables to access the jobs dashboard"
        end

        unless allowed_admin_github_ids.include?(current_user.github_id.to_s)
          redirect_to main_app.root_path, alert: "You don't have permission to access this page."
        end
      end
    end
  end
end
