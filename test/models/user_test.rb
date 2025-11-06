require "test_helper"

class UserTest < ActiveSupport::TestCase
  #--------------------------------------
  # SECURITY: OAuth Whitelist Tests
  #--------------------------------------

  test "from_omniauth creates user for whitelisted GitHub ID" do
    auth = build_github_auth(uid: 12345, nickname: "testuser", email: "test@example.com")

    user = User.from_omniauth(auth)

    assert user.persisted?
    assert_equal 12345, user.github_id
    assert_equal "testuser", user.github_username
    assert_equal "test@example.com", user.email
    assert_not_nil user.whitelisted_user_id
  end

  test "from_omniauth rejects non-whitelisted GitHub ID" do
    # GitHub ID 99999 is not in whitelisted_users fixtures
    auth = build_github_auth(uid: 99999, nickname: "hacker", email: "hacker@example.com")

    error = assert_raises(RuntimeError) do
      User.from_omniauth(auth)
    end

    assert_equal "Not whitelisted", error.message
    assert_nil User.find_by(github_id: 99999), "User should not be created"
  end

  test "from_omniauth updates existing user with fresh GitHub data" do
    # User exists from fixture
    existing_user = users(:one)
    original_email = existing_user.email

    # Simulate GitHub returning updated data
    auth = build_github_auth(
      uid: existing_user.github_id,
      nickname: existing_user.github_username,
      email: "newemail@example.com",
      name: "Updated Name"
    )

    user = User.from_omniauth(auth)

    assert_equal existing_user.id, user.id
    assert_equal "newemail@example.com", user.email
    assert_equal "Updated Name", user.github_name
  end

  #--------------------------------------
  # SECURITY: Rate Limiting Tests
  #--------------------------------------

  test "can_create_comparison? returns true when under daily limit" do
    user = users(:one)
    assert user.can_create_comparison?, "User should be able to create comparison"
  end

  test "can_create_comparison? returns false when at daily limit" do
    user = users(:one)

    # Create 20 comparisons (the daily limit)
    20.times do
      user.comparisons.create!(
        user_query: "test query",
        normalized_query: "test query",
        repos_compared_count: 1
      )
    end

    refute user.can_create_comparison?, "User should not be able to create more comparisons"
  end

  test "can_create_comparison? resets after 24 hours" do
    user = users(:one)

    # Create 20 comparisons from yesterday
    20.times do
      user.comparisons.create!(
        user_query: "test query",
        normalized_query: "test query",
        repos_compared_count: 1,
        created_at: 25.hours.ago
      )
    end

    # User should be able to create new comparisons today
    assert user.can_create_comparison?, "Rate limit should reset after 24 hours"
  end

  test "daily_comparison_limit returns 20" do
    user = users(:one)
    assert_equal 20, user.daily_comparison_limit
  end

  private

  # Helper to build GitHub OAuth response hash
  def build_github_auth(uid:, nickname:, email:, name: "Test User")
    OpenStruct.new(
      provider: "github",
      uid: uid.to_s,
      info: OpenStruct.new(
        nickname: nickname,
        email: email,
        name: name,
        image: "https://avatars.githubusercontent.com/u/#{uid}"
      )
    )
  end
end
