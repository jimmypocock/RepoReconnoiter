class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Redirect Render subdomain to custom domain (canonical URL enforcement)
  before_action :redirect_to_canonical_domain

  #--------------------------------------
  # DEVISE CUSTOMIZATION
  #--------------------------------------

  # Override Devise's default behavior when authentication fails
  # Redirect to root with message instead of /users/sign_in (which doesn't exist for OAuth-only)
  def authenticate_user!
    unless user_signed_in?
      redirect_to root_path, alert: "Please sign in with GitHub to continue."
    end
  end

  # Redirect to root after sign out
  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  # Redirect to root after sign in
  def after_sign_in_path_for(_resource_or_scope)
    root_path
  end

  private

  #--------------------------------------
  # CANONICAL DOMAIN ENFORCEMENT
  #--------------------------------------

  def redirect_to_canonical_domain
    return unless Rails.env.production?

    canonical_host = "reporeconnoiter.com"
    return if request.host == canonical_host

    # Redirect from www or Render subdomain to canonical domain (non-www)
    if request.host.in?([ "www.reporeconnoiter.com", "reporeconnoiter.onrender.com" ])
      redirect_to "https://#{canonical_host}#{request.fullpath}", status: :moved_permanently, allow_other_host: true
    end
  end
end
