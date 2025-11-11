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

  #--------------------------------------
  # SECURITY: Admin Access Control
  #--------------------------------------

  test "admin? returns true when user GitHub ID in ALLOWED_ADMIN_GITHUB_IDS" do
    # Stub env var with user's GitHub ID
    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: "12345,67890" do
      admin_user = users(:one) # has github_id: 12345
      assert admin_user.admin?, "User with ID 12345 should be admin"
    end
  end

  test "admin? returns false when user GitHub ID not in ALLOWED_ADMIN_GITHUB_IDS" do
    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: "67890" do
      regular_user = users(:one) # has github_id: 12345
      refute regular_user.admin?, "User with ID 12345 should not be admin"
    end
  end

  test "admin? returns false when ALLOWED_ADMIN_GITHUB_IDS is empty" do
    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: "" do
      user = users(:one)
      refute user.admin?, "Empty admin IDs should deny all users (fail-closed)"
    end
  end

  test "admin? returns false when ALLOWED_ADMIN_GITHUB_IDS is nil" do
    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: nil do
      user = users(:one)
      refute user.admin?, "Nil admin IDs should deny all users (fail-closed)"
    end
  end

  test "admin? handles whitespace in ALLOWED_ADMIN_GITHUB_IDS" do
    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: " 12345 , 67890 " do
      admin_user = users(:one) # has github_id: 12345
      assert admin_user.admin?, "Should handle whitespace in env var"
    end
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
