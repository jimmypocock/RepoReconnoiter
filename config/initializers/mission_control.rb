# Mission Control - Jobs configuration
# We handle authentication at the routing level with Devise (authenticate :user block)
# So we just need to tell Mission Control to skip its HTTP Basic Auth

# This prevents Mission Control from using HTTP Basic Auth
Rails.application.config.to_prepare do
  MissionControl::Jobs::ApplicationController.skip_before_action :authenticate_by_http_basic, raise: false

  # Add our own authentication check
  MissionControl::Jobs::ApplicationController.class_eval do
    before_action :check_admin_access!

    private

    def check_admin_access!
      unless current_user
        redirect_to root_path, alert: "You must be signed in to access this page."
        return
      end

      allowed_admin_github_ids = ENV.fetch("MISSION_CONTROL_ADMIN_IDS", "").split(",").map(&:strip).reject(&:empty?)

      # Require at least one admin ID to be configured
      if allowed_admin_github_ids.empty?
        raise "MISSION_CONTROL_ADMIN_IDS must be set in environment variables to access the jobs dashboard"
      end

      unless allowed_admin_github_ids.include?(current_user.github_id.to_s)
        redirect_to root_path, alert: "You don't have permission to access this page."
      end
    end
  end
end
