module ApplicationHelper
  include Pagy::Frontend

  def current_user_admin?
    return false unless user_signed_in?

    allowed_admin_github_ids = ENV.fetch("MISSION_CONTROL_ADMIN_IDS", "").split(",").map(&:strip).reject(&:empty?)
    allowed_admin_github_ids.include?(current_user.github_id.to_s)
  end
end
