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

  #--------------------------------------
  # USER PROFILE METHOD TESTS (Instance 2)
  #--------------------------------------

  test "comparisons_count_this_month returns correct count" do
    user = users(:one)

    # Clear existing comparisons
    user.comparisons.destroy_all

    # Create comparisons at different times
    Comparison.create!(user: user, user_query: "test1", normalized_query: "test1", created_at: 2.months.ago)
    Comparison.create!(user: user, user_query: "test2", normalized_query: "test2", created_at: 1.week.ago)
    Comparison.create!(user: user, user_query: "test3", normalized_query: "test3", created_at: Time.current)

    assert_equal 2, user.comparisons_count_this_month
  end

  test "remaining_comparisons_today returns correct count" do
    user = users(:one)

    # Clear existing comparisons
    user.comparisons.destroy_all

    # Create 18 comparisons today (under 20/day limit)
    18.times do |i|
      Comparison.create!(user: user, user_query: "test#{i}", normalized_query: "test#{i}", created_at: Time.current)
    end

    assert_equal 2, user.remaining_comparisons_today
  end

  test "remaining_comparisons_today returns 0 when limit exceeded" do
    user = users(:one)

    # Create 21 comparisons today (over 20/day limit)
    21.times do |i|
      Comparison.create!(user: user, user_query: "test#{i}", normalized_query: "test#{i}", created_at: Time.current)
    end

    assert_equal 0, user.remaining_comparisons_today
  end

  test "remaining_comparisons_today returns infinity for admins" do
    admin = users(:one)

    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: admin.github_id.to_s do
      # Create 30 comparisons (over normal 20/day limit)
      30.times do |i|
        Comparison.create!(user: admin, user_query: "test#{i}", normalized_query: "test#{i}", created_at: Time.current)
      end

      assert_equal Float::INFINITY, admin.remaining_comparisons_today
    end
  end

  test "remaining_analyses_today returns infinity for admins" do
    admin = users(:one)

    ClimateControl.modify ALLOWED_ADMIN_GITHUB_IDS: admin.github_id.to_s do
      assert_equal Float::INFINITY, admin.remaining_analyses_today
    end
  end

  test "total_ai_cost_spent returns sum of all user analyses costs" do
    user = users(:one)
    repo = repositories(:one)

    # Clear existing analyses
    user.analyses.destroy_all

    Analysis.create!(
      type: "Analysis",
      user: user,
      repository: repo,
      model_used: "gpt-5-mini",
      input_tokens: 100,
      output_tokens: 50,
      summary: "test1"
    )
    Analysis.create!(
      type: "Analysis",
      user: user,
      repository: repo,
      model_used: "gpt-5",
      input_tokens: 200,
      output_tokens: 100,
      summary: "test2"
    )

    # Other user's analysis (should not be included)
    Analysis.create!(
      type: "Analysis",
      user: users(:two),
      repository: repo,
      model_used: "gpt-5",
      input_tokens: 300,
      output_tokens: 150,
      summary: "test3"
    )

    # Cost should be automatically calculated by Analysis model
    assert_operator user.total_ai_cost_spent, :>, 0
  end

  test "ai_cost_spent_this_month returns only current month analysis costs" do
    user = users(:one)
    repo = repositories(:one)

    # Clear existing analyses
    user.analyses.destroy_all

    Analysis.create!(
      type: "Analysis",
      user: user,
      repository: repo,
      model_used: "gpt-5-mini",
      input_tokens: 100,
      output_tokens: 50,
      summary: "this month",
      created_at: Time.current
    )
    Analysis.create!(
      type: "Analysis",
      user: user,
      repository: repo,
      model_used: "gpt-5",
      input_tokens: 200,
      output_tokens: 100,
      summary: "last month",
      created_at: 2.months.ago
    )

    this_month_cost = user.ai_cost_spent_this_month
    total_cost = user.total_ai_cost_spent

    assert_operator this_month_cost, :>, 0
    assert_operator total_cost, :>, this_month_cost
  end

  test "soft_delete! anonymizes user data" do
    user = users(:one)
    original_email = user.email
    original_username = user.github_username

    user.soft_delete!
    user.reload

    assert_not_nil user.deleted_at
    assert_not_equal original_email, user.email
    assert user.email.start_with?("deleted_")
    assert_not_equal original_username, user.github_username
    assert user.github_username.start_with?("deleted_user_")
    assert_nil user.github_avatar_url
  end

  test "soft_delete! anonymizes user's comparisons" do
    user = users(:one)
    comparison = Comparison.create!(user: user, user_query: "test", normalized_query: "test")

    user.soft_delete!
    comparison.reload

    assert_nil comparison.user_id
  end

  test "soft_delete! anonymizes user's analyses" do
    user = users(:one)
    repo = repositories(:one)
    analysis = Analysis.create!(
      type: "Analysis",
      user: user,
      repository: repo,
      model_used: "gpt-5-mini",
      input_tokens: 100,
      output_tokens: 50,
      summary: "test"
    )

    user.soft_delete!
    analysis.reload

    assert_nil analysis.user_id
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
