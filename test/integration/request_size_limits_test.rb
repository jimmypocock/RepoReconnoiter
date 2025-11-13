require "test_helper"

class RequestSizeLimitsTest < ActionDispatch::IntegrationTest
  #--------------------------------------
  # SETUP
  #--------------------------------------

  def setup
    # Create a test API key for authenticated requests
    result = ApiKey.generate(name: "Request Size Test Key")
    @api_key = result[:api_key]
    @raw_key = result[:raw_key]
  end

  def teardown
    # Clean up test API key
    @api_key&.destroy
  end

  def auth_headers
    { "Authorization" => "Bearer #{@raw_key}" }
  end

  #--------------------------------------
  # REQUEST SIZE LIMIT TESTS
  #--------------------------------------

  test "allows API requests under 1MB" do
    # Small payload (1KB) - should pass
    small_payload = { search: "test" * 250 }.to_json  # ~1KB

    get v1_comparisons_path,
        headers: auth_headers.merge("Content-Type" => "application/json"),
        params: small_payload,
        as: :json

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "rejects API requests over 1MB with 413 status" do
    # Large payload (2MB) - should fail
    large_payload = "x" * (2 * 1024 * 1024)  # 2MB

    # Use post to actually send body content (GET typically ignores body)
    # Note: We're testing the middleware, not the actual endpoint functionality
    post v1_comparisons_path,
         params: large_payload,
         headers: auth_headers.merge(
           "Content-Type" => "application/json",
           "Content-Length" => large_payload.bytesize.to_s
         )

    assert_response :content_too_large  # 413
    assert_equal "application/json", response.content_type

    json = JSON.parse(response.body)
    assert_equal "Request payload too large", json["error"]["message"]
    assert_includes json["error"]["details"].first, "Maximum request size is 1MB"
    assert_equal 1048576, json["error"]["max_size_bytes"]
  end

  test "request size limit only applies to API endpoints" do
    # Large POST to non-API endpoint should not be blocked by our middleware
    # (Rails has its own limits, but our middleware only checks /api/v1/*)
    large_payload = "x" * (2 * 1024 * 1024)  # 2MB

    # POST to a non-API route (comparisons creation is a web route, not API)
    # This should not trigger our RequestSizeLimiter middleware
    # Note: This will fail for other reasons (authentication, validation, etc.)
    # but NOT because of payload size
    post comparisons_path,
         params: { user_query: large_payload },
         headers: { "Content-Length" => large_payload.bytesize.to_s }

    # Should get redirected to login or get 422, NOT 413
    assert_not_equal 413, response.status, "Web UI requests should not be blocked by RequestSizeLimiter"
  end

  test "request size check happens before authentication" do
    # Large payload without API key - should get 413, not 401
    # This proves the middleware runs BEFORE the authentication check
    large_payload = "x" * (2 * 1024 * 1024)  # 2MB

    post v1_comparisons_path,
         params: large_payload,
         headers: {
           "Content-Type" => "application/json",
           "Content-Length" => large_payload.bytesize.to_s
         }

    # Should get 413 (content too large), not 401 (unauthorized)
    assert_response :content_too_large
    json = JSON.parse(response.body)
    assert_equal "Request payload too large", json["error"]["message"]
  end

  test "request size limit is exactly 1MB" do
    # Test boundary condition: 1MB exactly should pass
    # Note: GET requests don't typically have bodies, so we use a small query param instead
    # The middleware checks Content-Length header, so we're testing the boundary logic

    # For a more realistic test, use POST with exactly 1MB payload
    one_mb_payload = "x" * (1024 * 1024)  # Exactly 1MB

    post v1_comparisons_path,
         params: one_mb_payload,
         headers: auth_headers.merge(
           "Content-Type" => "text/plain",  # Use plain text to avoid JSON parsing errors
           "Content-Length" => one_mb_payload.bytesize.to_s
         )

    # Should get 401 (unauthorized - requires user JWT), NOT 413 (content too large)
    # This proves the content size check passed (1MB is at the limit)
    assert_response :unauthorized  # POST route now exists but requires user authentication
  end

  test "request size limit over 1MB by 1 byte fails" do
    # Test boundary condition: 1MB + 1 byte should fail
    over_one_mb_payload = "x" * (1024 * 1024 + 1)  # 1MB + 1 byte

    post v1_comparisons_path,
         params: over_one_mb_payload,
         headers: auth_headers.merge(
           "Content-Type" => "application/json",
           "Content-Length" => over_one_mb_payload.bytesize.to_s
         )

    assert_response :content_too_large
  end

  #--------------------------------------
  # IP BLOCKLIST TESTS (Rack::Attack)
  #--------------------------------------

  # Note: IP blocking tests are skipped because Rack::Attack initializes
  # the blocklist at boot time from ENV["BLOCKED_IPS"].
  # Changing ENV vars during tests doesn't update Rack::Attack's cache.
  #
  # These features are verified by:
  # 1. Manual testing: BLOCKED_IPS="1.2.3.4" bin/rails server
  # 2. Rake tasks: bin/rails ips:test[1.2.3.4]
  # 3. Unit tests for the ENV parsing logic (if needed)
  #
  # For full integration testing of IP blocking, you'd need to:
  # - Restart Rails between tests (slow)
  # - Mock Rack::Attack's cache (fragile)
  # - Test at a different level (Rack middleware unit test)

  # test "blocked IPs receive 403 Forbidden" do
  #   # Skipped - requires Rack::Attack reinitialization
  # end

  # test "non-blocked IPs can access API with valid key" do
  #   # Skipped - requires Rack::Attack reinitialization
  # end
end
