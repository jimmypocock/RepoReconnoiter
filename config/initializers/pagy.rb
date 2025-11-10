# Pagy initializer file
# See https://ddnexus.github.io/pagy/docs/api/backend

# Pagy v43+ integrates extras directly into core - no need to require them

# Pagy defaults
Pagy.options[:items] = 20
Pagy.options[:page_key] = "page"  # Changed from :page_param (symbol) to :page_key (string) in v43
