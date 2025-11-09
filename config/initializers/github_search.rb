# GitHub Search Configuration
#
# Minimum star thresholds for repository searches
# - min_stars: Default threshold for most searches (niche libraries, language-specific tools)
# - popular_min_stars: Higher threshold for very common tools (React, Jest, etc.)

Rails.application.config.github_search = {
  min_stars: 50,
  popular_min_stars: 500
}
