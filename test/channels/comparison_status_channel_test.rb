require "test_helper"

class ComparisonStatusChannelTest < ActionCable::Channel::TestCase
  def setup
    @user = users(:one)
    @session_id = SecureRandom.uuid
  end

  test "subscribes with valid session_id and user" do
    stub_connection(current_user: @user)
    subscribe(session_id: @session_id)

    assert subscription.confirmed?
    assert_has_stream "comparison_progress_#{@session_id}"
  end

  test "rejects subscription without session_id" do
    stub_connection(current_user: @user)
    subscribe

    assert subscription.rejected?
  end

  test "rejects subscription with blank session_id" do
    stub_connection(current_user: @user)
    subscribe(session_id: "")

    assert subscription.rejected?
  end

  test "receives broadcast messages" do
    stub_connection(current_user: @user)
    subscribe(session_id: @session_id)

    # Simulate a progress broadcast
    ActionCable.server.broadcast(
      "comparison_progress_#{@session_id}",
      { type: "progress", message: "Processing...", percentage: 50 }
    )

    assert_broadcast_on(
      "comparison_progress_#{@session_id}",
      { type: "progress", message: "Processing...", percentage: 50 }
    )
  end

  test "unsubscribes and stops streams" do
    stub_connection(current_user: @user)
    subscribe(session_id: @session_id)

    assert subscription.confirmed?

    perform :unsubscribed

    assert_no_streams
  end
end
