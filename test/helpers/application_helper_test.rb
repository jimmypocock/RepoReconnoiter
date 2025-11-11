require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "safe_github_url returns valid GitHub URLs" do
    valid_url = "https://github.com/rails/rails"
    assert_equal valid_url, safe_github_url(valid_url)
  end

  test "safe_github_url rejects non-HTTPS URLs" do
    assert_nil safe_github_url("http://github.com/rails/rails")
  end

  test "safe_github_url rejects non-GitHub domains" do
    assert_nil safe_github_url("https://evil.com/rails/rails")
  end

  test "safe_github_url rejects invalid URIs" do
    assert_nil safe_github_url("javascript:alert(1)")
  end

  test "safe_github_url handles blank input" do
    assert_nil safe_github_url(nil)
    assert_nil safe_github_url("")
  end
end
