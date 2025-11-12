# Pagy initializer file
# See https://ddnexus.github.io/pagy/docs/api/backend

# Pagy v43+ integrates extras directly into core - no need to require them

# Pagy defaults
Pagy.options[:limit] = 20  # Changed from :items to :limit in v43
Pagy.options[:page_key] = "page"  # Changed from :page_param to :page_key in v43
