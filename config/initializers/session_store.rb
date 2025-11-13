# Session Store Configuration
# Configures secure session cookies with __Host- prefix
#
# __Host- prefix requirements:
# - Secure flag must be set (HTTPS only)
# - Path must be / (root)
# - Domain must not be set
#
# This provides defense-in-depth against:
# - Subdomain attacks
# - Man-in-the-middle attacks
# - Cookie fixation attacks
#
Rails.application.config.session_store :cookie_store,
  key: Rails.env.production? ? "__Host-_repo_reconnoiter_session" : "_repo_reconnoiter_session",
  secure: Rails.env.production?,  # HTTPS only in production
  httponly: true,                  # Prevent JavaScript access
  same_site: :lax                  # CSRF protection
