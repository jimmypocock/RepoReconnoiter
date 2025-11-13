# SessionExchangeController
# Exchanges JWT token for Rails session and redirects to authenticated pages
#
# This allows Next.js users to seamlessly access Rails-only UIs
# (admin tools, dev tools, etc.) without requiring separate login.
#
# Usage from Next.js:
#   // Admin pages (requires admin role)
#   window.location.href = `${railsUrl}/session_exchange?token=${jwt}&redirect=/admin/jobs`
#
#   // Authenticated pages (any logged-in user)
#   window.location.href = `${railsUrl}/session_exchange?token=${jwt}&redirect=/profile`
#
# Security:
#   - Validates JWT token
#   - Checks user permissions for requested path
#   - Whitelists allowed redirect paths to prevent open redirects
#
class SessionExchangeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]

  # Whitelisted redirect paths for security
  # Add new paths here as needed
  ALLOWED_REDIRECTS = {
    # Admin-only paths (require admin role)
    admin: [
      "/admin/jobs",     # Mission Control
      "/admin/stats",    # Admin stats dashboard
      "/admin/users"     # User management
    ],
    # Authenticated paths (any logged-in user)
    authenticated: [
      "/profile",        # User profile
      "/repositories"    # User's repositories
    ]
  }.freeze

  # GET /session_exchange?token=JWT&redirect=/admin/jobs
  def create
    token = params[:token]
    redirect_path = params[:redirect]

    # Validate token presence
    unless token.present?
      redirect_to root_path, alert: "Authentication required"
      return
    end

    # Validate redirect path is whitelisted
    unless allowed_redirect?(redirect_path)
      redirect_to root_path, alert: "Invalid redirect path"
      return
    end

    # Decode and validate JWT
    payload = JsonWebToken.decode(token)
    user = User.find_by(id: payload[:user_id])

    unless user
      redirect_to root_path, alert: "User not found"
      return
    end

    # Check permissions for requested path
    unless has_permission?(user, redirect_path)
      redirect_to root_path, alert: "Access denied"
      return
    end

    # Create Rails session (sign in via Warden/Devise)
    sign_in(user)

    # Redirect to requested page
    redirect_to redirect_path
  rescue JWT::DecodeError => e
    redirect_to root_path, alert: "Invalid or expired token"
  end

  private

  # Check if redirect path is in whitelist
  def allowed_redirect?(path)
    return false if path.blank?
    ALLOWED_REDIRECTS.values.flatten.include?(path)
  end

  # Check if user has permission to access the path
  def has_permission?(user, path)
    if ALLOWED_REDIRECTS[:admin].include?(path)
      user.admin?
    elsif ALLOWED_REDIRECTS[:authenticated].include?(path)
      true  # Any authenticated user
    else
      false
    end
  end
end
