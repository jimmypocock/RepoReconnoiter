require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "sets X-Frame-Options header" do
    get root_path
    assert_equal "DENY", response.headers["X-Frame-Options"]
  end

  test "sets X-Content-Type-Options header" do
    get root_path
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "sets X-XSS-Protection header" do
    get root_path
    assert_equal "1; mode=block", response.headers["X-XSS-Protection"]
  end

  test "sets Referrer-Policy header" do
    get root_path
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
  end

  test "sets Permissions-Policy header" do
    get root_path
    permissions_policy = response.headers["Permissions-Policy"]
    assert_not_nil permissions_policy, "Permissions-Policy header should be set"
    assert_includes permissions_policy, "geolocation=()"
    assert_includes permissions_policy, "camera=()"
    assert_includes permissions_policy, "microphone=()"
  end

  test "sets Content-Security-Policy header" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_not_nil csp, "Content-Security-Policy header should be set"
    assert_includes csp, "default-src"
    assert_includes csp, "script-src"
    assert_includes csp, "style-src"
  end

  test "does not set HSTS in development" do
    get root_path
    assert_nil response.headers["Strict-Transport-Security"],
               "HSTS should not be set in development environment"
  end
end
