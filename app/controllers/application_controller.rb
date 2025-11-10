class ApplicationController < ActionController::Base
  include Pagy::Method

  allow_browser versions: :modern
  stale_when_importmap_changes
  before_action :redirect_to_canonical_domain

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def after_sign_in_path_for(_resource_or_scope)
    root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to root_path, alert: "Please sign in with GitHub to continue."
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def redirect_to_canonical_domain
    return unless Rails.env.production?

    canonical_host = "reporeconnoiter.com"
    return if request.host == canonical_host

    if request.host.in?([ "www.reporeconnoiter.com", "reporeconnoiter.onrender.com" ])
      redirect_to "https://#{canonical_host}#{request.fullpath}", status: :moved_permanently, allow_other_host: true
    end
  end
end
