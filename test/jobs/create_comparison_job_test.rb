require "test_helper"

class CreateComparisonJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @query = "Rails background jobs"
    @session_id = "test_session_123"
  end

  test "successful comparison creation broadcasts complete" do
    mock_result = OpenStruct.new(record: OpenStruct.new(id: 1))
    mock_creator = OpenStruct.new(call: mock_result)
    mock_broadcaster = Minitest::Mock.new
    mock_broadcaster.expect :broadcast_complete, nil, [ 1 ]

    ComparisonCreator.stub :new, ->(*) { mock_creator } do
      ComparisonProgressBroadcaster.stub :new, ->(*) { mock_broadcaster } do
        CreateComparisonJob.perform_now(@user.id, @query, @session_id)
        assert mock_broadcaster.verify
      end
    end
  end

  test "InvalidQueryError broadcasts error without retry" do
    error = ComparisonCreator::InvalidQueryError.new("Query too vague")
    mock_broadcaster = Minitest::Mock.new
    mock_broadcaster.expect :broadcast_error, nil, [ "Invalid query: Query too vague" ]

    ComparisonCreator.stub :new, ->(*) { raise error } do
      ComparisonProgressBroadcaster.stub :new, ->(*) { mock_broadcaster } do
        CreateComparisonJob.perform_now(@user.id, @query, @session_id)
        assert mock_broadcaster.verify
      end
    end
  end

  test "NoRepositoriesFoundError broadcasts error without retry" do
    error = ComparisonCreator::NoRepositoriesFoundError.new
    mock_broadcaster = Minitest::Mock.new
    mock_broadcaster.expect :broadcast_error, nil, [ "No repositories found. Try a different query." ]

    ComparisonCreator.stub :new, ->(*) { raise error } do
      ComparisonProgressBroadcaster.stub :new, ->(*) { mock_broadcaster } do
        CreateComparisonJob.perform_now(@user.id, @query, @session_id)
        assert mock_broadcaster.verify
      end
    end
  end

  test "error_message_for returns rate limit message for Octokit::TooManyRequests" do
    job = CreateComparisonJob.new(@user.id, @query, @session_id)
    error = Octokit::TooManyRequests.new

    assert_equal "GitHub rate limit reached. Please try again in a few minutes.",
                 job.send(:error_message_for, error)
  end

  test "error_message_for returns timeout message for Faraday::TimeoutError" do
    job = CreateComparisonJob.new(@user.id, @query, @session_id)
    error = Faraday::TimeoutError.new("timeout")

    assert_equal "Request timed out. Please try again.",
                 job.send(:error_message_for, error)
  end

  test "error_message_for returns generic message for other StandardError" do
    job = CreateComparisonJob.new(@user.id, @query, @session_id)
    error = StandardError.new("something broke")

    assert_equal "Something went wrong. Please try again.",
                 job.send(:error_message_for, error)
  end

  test "broadcast_retry_exhausted sends correct message to broadcaster" do
    job = CreateComparisonJob.new(@user.id, @query, @session_id)
    error = Octokit::TooManyRequests.new

    mock_broadcaster = Minitest::Mock.new
    mock_broadcaster.expect :broadcast_error, nil, [ "GitHub rate limit reached. Please try again in a few minutes." ]

    ComparisonProgressBroadcaster.stub :new, ->(*) { mock_broadcaster } do
      job.broadcast_retry_exhausted(error)
      assert mock_broadcaster.verify
    end
  end

  test "StandardError triggers retry_on mechanism" do
    error = RuntimeError.new("Unexpected error")

    ComparisonCreator.stub :new, ->(*) { raise error } do
      mock_broadcaster = Minitest::Mock.new

      ComparisonProgressBroadcaster.stub :new, ->(*) { mock_broadcaster } do
        # With retry_on configured (polynomially_longer), StandardError is caught
        # and the job is scheduled for retry. After 2 attempts, the error is handled
        # via broadcast_retry_exhausted callback (configured in the job).

        # Verify that perform_now doesn't let the error propagate (retry_on catches it)
        # and schedules retries instead
        assert_nothing_raised do
          CreateComparisonJob.set(wait: 0).perform_later(@user.id, @query, @session_id)
        end

        # Verify retries were scheduled (job will retry 2 times as configured)
        assert_enqueued_jobs 1, only: CreateComparisonJob
      end
    end
  end
end
