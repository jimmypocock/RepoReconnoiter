# API Documentation Controller
# Serves OpenAPI specification in multiple formats
# Documentation is public (no auth required)
#
module Api
  module V1
    class DocsController < BaseController
      # Skip authentication for documentation endpoints (public access)
      skip_before_action :authenticate_api_key!

      # GET /api/v1/openapi.json
      # Returns OpenAPI spec as JSON (for Swagger UI)
      # Resolves all external $ref references into a single document
      def openapi_json
        base_path = Rails.root.join("docs", "api")
        yaml_content = File.read(base_path.join("openapi.yml"))
        openapi_hash = YAML.safe_load(yaml_content, aliases: true)

        # Recursively resolve all $ref external file references
        resolved_hash = resolve_refs(openapi_hash, base_path)

        render json: resolved_hash
      end

      # GET /api/v1/openapi.yml
      # Returns OpenAPI spec as YAML (for AI/programmatic access)
      def openapi_yaml
        send_file Rails.root.join("docs", "api", "openapi.yml"),
                  type: "application/x-yaml",
                  disposition: "inline"
      end

      private

      #--------------------------------------
      # PRIVATE METHODS
      #--------------------------------------

      # Recursively resolve all $ref external file references
      # @param obj [Hash, Array, Object] The object to process
      # @param base_path [Pathname] The base directory for resolving relative paths
      # @param current_file [Pathname, nil] The current file being processed (for nested refs)
      # @return [Hash, Array, Object] The object with all $refs resolved
      def resolve_refs(obj, base_path, current_file = nil)
        case obj
        when Hash
          if obj.key?("$ref") && obj["$ref"].is_a?(String)
            # This is a $ref - resolve it
            ref_path = obj["$ref"]
            if ref_path.start_with?("./")
              # External file reference - resolve relative to current file's directory
              ref_base = current_file ? current_file.dirname : base_path
              file_path = ref_base.join(ref_path.delete_prefix("./"))

              if File.exist?(file_path)
                ref_content = YAML.safe_load(File.read(file_path), aliases: true)
                # Pass the resolved file path so nested refs are relative to it
                resolve_refs(ref_content, base_path, file_path)
              else
                obj # Return original if file doesn't exist
              end
            else
              obj # Internal reference or URL - leave as is
            end
          else
            # Regular hash - process all values recursively
            obj.transform_values { |v| resolve_refs(v, base_path, current_file) }
          end
        when Array
          obj.map { |item| resolve_refs(item, base_path, current_file) }
        else
          obj
        end
      end
    end
  end
end
