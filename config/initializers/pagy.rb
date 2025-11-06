# Pagy initializer file
# See https://ddnexus.github.io/pagy/docs/api/backend

require "pagy/extras/array"

# Pagy defaults
Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:page_param] = :page
