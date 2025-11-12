# Middleware to enforce request size limits for API endpoints
#
# Protects against large payload attacks and accidental misuse.
# Returns 413 Payload Too Large for requests exceeding 1MB.
#
# Registered in: config/application.rb
class RequestSizeLimiter
  # Maximum request body size (1MB is very generous for a read-only API)
  # Typical API requests:
  #   - GET with query params: 1-5KB
  #   - POST with filters: 5-10KB
  #   - Large legitimate request: 50-100KB
  MAX_REQUEST_SIZE = 1.megabyte

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Only check API endpoints (don't limit web UI form uploads)
    if api_endpoint?(request) && exceeds_size_limit?(env)
      return payload_too_large_response
    end

    @app.call(env)
  end

  private

  def api_endpoint?(request)
    request.path.start_with?("/api/v1/")
  end

  def exceeds_size_limit?(env)
    content_length = env["CONTENT_LENGTH"].to_i
    content_length > MAX_REQUEST_SIZE
  end

  def payload_too_large_response
    [
      413,
      {
        "Content-Type" => "application/json",
        "Content-Length" => error_body.bytesize.to_s
      },
      [ error_body ]
    ]
  end

  def error_body
    @error_body ||= {
      error: {
        message: "Request payload too large",
        details: [
          "Maximum request size is #{MAX_REQUEST_SIZE / 1.megabyte}MB",
          "This is a read-only API - large payloads are not expected"
        ],
        max_size_bytes: MAX_REQUEST_SIZE
      }
    }.to_json
  end
end
