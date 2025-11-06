# Turbo configuration
#
# Disable Turbo Native routes (for iOS/Android mobile apps)
# We're building a web app, not a mobile app, so we don't need:
# - /recede_historical_location
# - /resume_historical_location
# - /refresh_historical_location

Rails.application.config.turbo.draw_routes = false
