# Mission Control - Jobs configuration
# We handle authentication at the routing level with Devise (authenticate :user block)
# So we just need to tell Mission Control to skip its HTTP Basic Auth

# This prevents Mission Control from using HTTP Basic Auth
Rails.application.config.to_prepare do
  MissionControl::Jobs::ApplicationController.skip_before_action :authenticate_by_http_basic, raise: false

  # Add our own admin check (reuses User#admin? logic)
  MissionControl::Jobs::ApplicationController.class_eval do
    before_action :require_admin!

    private

    def require_admin!
      unless current_user
        redirect_to root_path, alert: "You must be signed in to access this page."
        return
      end

      unless current_user.admin?
        redirect_to root_path, alert: "You don't have permission to access this page."
      end
    end
  end
end
