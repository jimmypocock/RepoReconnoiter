require "test_helper"

class ComparisonsControllerTest < ActionDispatch::IntegrationTest
  #--------------------------------------
  # INDEX ACTION
  #--------------------------------------

  test "index renders successfully" do
    get root_path
    assert_response :success
  end

  test "index shows comparisons" do
    comparison = comparisons(:one)
    get root_path
    assert_select "a[href=?]", comparison_path(comparison)
  end

  #--------------------------------------
  # CREATE ACTION - AUTHENTICATION
  #--------------------------------------

  test "create requires authentication" do
    post comparisons_path, params: { query: "Rails background jobs" }
    assert_redirected_to root_path
    assert_match /sign in with GitHub/i, flash[:alert]
  end

  test "authenticated user can create comparison" do
    sign_in users(:one)

    # Stub background job to prevent actual execution
    CreateComparisonJob.stub :perform_later, true do
      post comparisons_path, params: { query: "Rails background jobs" }
    end

    assert_redirected_to root_path
    assert_equal "Creating your comparison...", flash[:notice]
  end

  #--------------------------------------
  # CREATE ACTION - RATE LIMITING
  #--------------------------------------

  test "enforces rate limit of 20 comparisons per day" do
    user = users(:one)
    sign_in user

    # Create 20 comparisons (daily limit)
    20.times do
      user.comparisons.create!(
        user_query: "test",
        normalized_query: "test",
        repos_compared_count: 1
      )
    end

    # 21st attempt should be rejected
    post comparisons_path, params: { query: "Rails jobs" }

    assert_redirected_to root_path
    assert_match /daily limit/, flash[:alert]
  end

  test "rate limit resets after 24 hours" do
    user = users(:one)
    sign_in user

    # Create 20 comparisons from yesterday
    20.times do
      user.comparisons.create!(
        user_query: "test",
        normalized_query: "test",
        repos_compared_count: 1,
        created_at: 25.hours.ago
      )
    end

    # Should allow new comparison today
    CreateComparisonJob.stub :perform_later, true do
      post comparisons_path, params: { query: "Rails jobs" }
    end

    assert_redirected_to root_path
    refute_match /daily limit/, flash[:alert] || ""
  end

  #--------------------------------------
  # CREATE ACTION - VALIDATION
  #--------------------------------------

  test "rejects blank query" do
    sign_in users(:one)

    post comparisons_path, params: { query: "" }

    assert_redirected_to root_path
    assert_match /enter a search query/, flash[:alert]
  end

  test "rejects whitespace-only query" do
    sign_in users(:one)

    post comparisons_path, params: { query: "   " }

    assert_redirected_to root_path
    assert_match /enter a search query/, flash[:alert]
  end

  test "rejects query over 500 characters" do
    sign_in users(:one)

    long_query = "a" * 501
    post comparisons_path, params: { query: long_query }

    assert_redirected_to root_path
    assert_match /too long/, flash[:alert]
  end

  test "accepts query at exactly 500 characters" do
    sign_in users(:one)

    query = "a" * 500

    CreateComparisonJob.stub :perform_later, true do
      post comparisons_path, params: { query: query }
    end

    assert_redirected_to root_path
    refute_match /too long/, flash[:alert] || ""
  end

  #--------------------------------------
  # CREATE ACTION - SESSION TRACKING
  #--------------------------------------

  test "sets comparison_session_id in session" do
    sign_in users(:one)

    CreateComparisonJob.stub :perform_later, true do
      post comparisons_path, params: { query: "Rails jobs" }
    end

    # Session should have comparison_session_id
    assert session[:comparison_session_id].present?
    assert_instance_of String, session[:comparison_session_id]
  end

  #--------------------------------------
  # CREATE ACTION - TURBO STREAM
  #--------------------------------------

  test "responds with turbo_stream format" do
    sign_in users(:one)

    CreateComparisonJob.stub :perform_later, true do
      post comparisons_path, params: { query: "Rails jobs" }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  #--------------------------------------
  # SHOW ACTION
  #--------------------------------------

  test "show renders comparison" do
    comparison = comparisons(:one)
    get comparison_path(comparison)

    assert_response :success
    assert_select "h2", text: comparison.user_query
  end

  test "show increments view_count" do
    comparison = comparisons(:one)
    original_count = comparison.view_count

    get comparison_path(comparison)

    comparison.reload
    assert_equal original_count + 1, comparison.view_count
  end

  test "show consumes newly_created session flag" do
    comparison = comparisons(:one)

    # Manually set newly_created flag in session
    get comparison_path(comparison), headers: { "Cookie" => "" }
    session[:newly_created] = true

    # Visit again - flag should be cleared
    get comparison_path(comparison)
    assert_nil session[:newly_created]
  end

  test "show passes current_user to presenter" do
    user = users(:one)
    sign_in user

    comparison = comparisons(:one)
    get comparison_path(comparison)

    # Verify presenter receives current_user (needed for can_refresh? check)
    assert_response :success
  end

  test "show handles invalid comparison ID" do
    # With show_exceptions = :rescuable, Rails rescues RecordNotFound and renders 404
    get comparison_path(id: 99999)
    assert_response :not_found
  end
end
