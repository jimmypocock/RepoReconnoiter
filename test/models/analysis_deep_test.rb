require "test_helper"

class AnalysisDeepTest < ActiveSupport::TestCase
  #--------------------------------------
  # SETUP
  #--------------------------------------

  def setup
    @user = users(:one)
    @repository = repositories(:one)
  end

  #--------------------------------------
  # BUDGET RESERVATION TESTS
  #--------------------------------------

  test "remaining_budget_today includes pending cost reservations" do
    # Create a processing analysis status with pending cost
    AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: @user,
      repository: @repository,
      status: :processing,
      pending_cost_usd: 0.08
    )

    # Remaining budget should be: DAILY_BUDGET - pending_cost
    expected_remaining = AnalysisDeep::DAILY_BUDGET - 0.08
    assert_in_delta expected_remaining, AnalysisDeep.remaining_budget_today, 0.001
  end

  test "remaining_budget_today ignores completed analysis statuses" do
    # Create a completed status (should not count toward pending)
    AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: @user,
      repository: @repository,
      status: :completed,
      pending_cost_usd: 0.08
    )

    # Remaining budget should be full (completed statuses don't count)
    assert_equal AnalysisDeep::DAILY_BUDGET, AnalysisDeep.remaining_budget_today
  end

  test "remaining_budget_today ignores failed analysis statuses" do
    # Create a failed status (should not count toward pending)
    AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: @user,
      repository: @repository,
      status: :failed,
      pending_cost_usd: 0.08,
      error_message: "Test error"
    )

    # Remaining budget should be full (failed statuses don't count)
    assert_equal AnalysisDeep::DAILY_BUDGET, AnalysisDeep.remaining_budget_today
  end

  test "remaining_budget_today sums multiple pending reservations" do
    # Create multiple processing statuses
    3.times do |i|
      AnalysisStatus.create!(
        session_id: "session-#{i}",
        user: @user,
        repository: @repository,
        status: :processing,
        pending_cost_usd: 0.08
      )
    end

    # Remaining budget should subtract all 3 reservations
    expected_remaining = AnalysisDeep::DAILY_BUDGET - (3 * 0.08)
    assert_in_delta expected_remaining, AnalysisDeep.remaining_budget_today, 0.001
  end

  test "remaining_budget_today only counts today's pending costs" do
    # Create a processing status from yesterday
    yesterday_status = AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: @user,
      repository: @repository,
      status: :processing,
      pending_cost_usd: 0.08
    )
    yesterday_status.update_column(:created_at, 1.day.ago)

    # Remaining budget should be full (yesterday's pending costs don't count)
    assert_equal AnalysisDeep::DAILY_BUDGET, AnalysisDeep.remaining_budget_today
  end

  test "can_create_today? returns false when pending costs would exceed budget" do
    # Fill the budget with pending reservations
    budget_remaining = AnalysisDeep::DAILY_BUDGET
    reservations_count = (budget_remaining / AnalysisDeep::ESTIMATED_COST).floor

    reservations_count.times do |i|
      AnalysisStatus.create!(
        session_id: "session-#{i}",
        user: @user,
        repository: @repository,
        status: :processing,
        pending_cost_usd: AnalysisDeep::ESTIMATED_COST
      )
    end

    # Should not be able to create another analysis
    assert_not AnalysisDeep.can_create_today?
  end

  test "can_create_today? returns true when budget has room" do
    # With fresh budget, should be able to create
    assert AnalysisDeep.can_create_today?
  end

  test "remaining_budget_today combines actual costs and pending reservations" do
    # Create a completed analysis with actual cost
    AnalysisDeep.create!(
      repository: @repository,
      user: @user,
      model_used: "gpt-5",
      readme_analysis: "Test",
      issues_analysis: "Test",
      maintenance_analysis: "Test",
      adoption_analysis: "Test",
      security_analysis: "Test",
      input_tokens: 1000,
      output_tokens: 500,
      is_current: true
    )
    actual_cost = AnalysisDeep.last.cost_usd

    # Create a pending reservation
    AnalysisStatus.create!(
      session_id: SecureRandom.uuid,
      user: @user,
      repository: @repository,
      status: :processing,
      pending_cost_usd: 0.08
    )

    # Remaining should subtract both actual and pending
    expected_remaining = AnalysisDeep::DAILY_BUDGET - actual_cost - 0.08
    assert_in_delta expected_remaining, AnalysisDeep.remaining_budget_today, 0.001
  end
end
