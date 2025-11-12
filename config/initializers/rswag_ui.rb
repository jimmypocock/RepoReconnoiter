Rswag::Ui.configure do |c|
  # Point to our OpenAPI specification endpoint
  # This loads the OpenAPI spec from /api/v1/openapi.json
  c.openapi_endpoint "/api/v1/openapi.json", "RepoReconnoiter API V1"

  # Swagger UI configuration options
  # See: https://github.com/swagger-api/swagger-ui/blob/master/docs/usage/configuration.md
  # NOTE: Use merge! to preserve the :urls array set by openapi_endpoint above
  c.config_object.merge!({
    displayRequestDuration: true,  # Show how long requests take
    persistAuthorization: true,    # Remember auth tokens across page reloads
    tryItOutEnabled: true,         # Enable "Try it out" by default
    filter: true,                  # Add search/filter box
    defaultModelsExpandDepth: 1,   # Show schema details by default
    docExpansion: "list"           # Show endpoints collapsed by tag
  })
end
