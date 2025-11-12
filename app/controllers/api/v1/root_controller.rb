# API root endpoint for discoverability
# Returns available endpoints and API information
#
module Api
  module V1
    class RootController < BaseController
      # GET /api/v1
      # Returns API version info and available endpoints
      def index
        render json: {
          version: "v1",
          endpoints: {
            comparisons: {
              url: v1_comparisons_url,
              methods: [ "GET" ],
              description: "List and search repository comparisons"
            },
            documentation: {
              openapi_json: v1_openapi_json_url,
              openapi_yaml: v1_openapi_yaml_url,
              swagger_ui: rswag_ui_url,
              description: "API documentation in OpenAPI 3.0 format"
            }
          },
          documentation_url: rswag_ui_url
        }
      end
    end
  end
end
