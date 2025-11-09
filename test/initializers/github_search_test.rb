require "test_helper"

class GithubSearchConfigTest < ActiveSupport::TestCase
  test "github_search config is loaded" do
    assert_not_nil Rails.application.config.github_search
  end

  test "github_search config has min_stars" do
    assert_equal 50, Rails.application.config.github_search[:min_stars]
  end

  test "github_search config has popular_min_stars" do
    assert_equal 500, Rails.application.config.github_search[:popular_min_stars]
  end
end
