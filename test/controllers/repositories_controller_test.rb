require "test_helper"

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  #--------------------------------------
  # AUTHENTICATION TESTS
  #--------------------------------------

  test "index requires authentication" do
    get repositories_path
    assert_redirected_to root_path
    assert_match /sign in with GitHub/i, flash[:alert]
  end

  test "show requires authentication" do
    repo = repositories(:one)
    get repository_path(repo)
    assert_redirected_to root_path
  end

  test "create_analysis requires authentication" do
    repo = repositories(:one)
    post create_analysis_repository_path(repo)
    assert_redirected_to root_path
  end

  #--------------------------------------
  # INDEX ACTION
  #--------------------------------------

  test "authenticated user can view repositories index" do
    sign_in users(:one)
    get repositories_path
    assert_response :success
  end

  test "index shows recent repositories" do
    sign_in users(:one)
    repo = repositories(:one)

    get repositories_path
    assert_response :success
    assert_select "a[href=?]", repository_path(repo)
  end

  test "index handles repository search" do
    sign_in users(:one)
    repo = repositories(:one)

    get repositories_path, params: { query: repo.full_name }

    # Should redirect to repository show page
    assert_redirected_to repository_path(repo)
  end

  test "index handles invalid repository URL" do
    sign_in users(:one)

    get repositories_path, params: { query: "not a valid url" }

    assert_response :success
    assert_match /invalid/i, flash[:alert] || ""
  end

  #--------------------------------------
  # SHOW ACTION
  #--------------------------------------

  test "authenticated user can view repository" do
    sign_in users(:one)
    repo = repositories(:one)

    get repository_path(repo)
    assert_response :success
    assert_select "h1", text: repo.full_name
  end

  test "show displays repository analyses" do
    sign_in users(:one)
    repo = repositories(:one)

    get repository_path(repo)
    assert_response :success
  end

  test "show handles non-existent repository" do
    sign_in users(:one)

    get repository_path(id: 99999)

    assert_redirected_to repositories_path
    assert_match /not found/i, flash[:alert]
  end

  #--------------------------------------
  # CREATE_ANALYSIS ACTION - RATE LIMITING
  #--------------------------------------

  test "create_analysis enforces user daily limit" do
    user = users(:one)
    repo = repositories(:one)
    sign_in user

    # Stub class methods to simulate user at limit
    AnalysisDeep.stub :can_create_today?, true do
      AnalysisDeep.stub :user_can_create_today?, false do
        post create_analysis_repository_path(repo)

        assert_redirected_to repository_path(repo)
        assert_match /daily limit/, flash[:alert]
      end
    end
  end

  test "create_analysis enforces global daily budget" do
    user = users(:one)
    repo = repositories(:one)
    sign_in user

    # Stub to simulate budget exceeded
    AnalysisDeep.stub :can_create_today?, false do
      post create_analysis_repository_path(repo)

      assert_redirected_to repository_path(repo)
      assert_match /budget/, flash[:alert]
    end
  end

  test "create_analysis succeeds when under limits" do
    user = users(:one)
    repo = repositories(:one)
    sign_in user

    # Stub both checks to pass
    AnalysisDeep.stub :can_create_today?, true do
      AnalysisDeep.stub :user_can_create_today?, true do
        # Stub job to prevent actual execution
        CreateDeepAnalysisJob.stub :perform_later, true do
          post create_analysis_repository_path(repo), as: :turbo_stream
        end

        assert_response :success
      end
    end
  end

  test "create_analysis enqueues background job" do
    user = users(:one)
    repo = repositories(:one)
    sign_in user

    # Stub rate limit checks
    AnalysisDeep.stub :can_create_today?, true do
      AnalysisDeep.stub :user_can_create_today?, true do
        # Verify job is enqueued
        job_called = false
        CreateDeepAnalysisJob.stub :perform_later, ->(*args) { job_called = true } do
          post create_analysis_repository_path(repo)
        end

        assert job_called, "CreateDeepAnalysisJob should be enqueued"
      end
    end
  end

  test "create_analysis responds with turbo_stream" do
    user = users(:one)
    repo = repositories(:one)
    sign_in user

    AnalysisDeep.stub :can_create_today?, true do
      AnalysisDeep.stub :user_can_create_today?, true do
        CreateDeepAnalysisJob.stub :perform_later, true do
          post create_analysis_repository_path(repo), as: :turbo_stream
        end

        assert_response :success
        assert_equal "text/vnd.turbo-stream.html", response.media_type
      end
    end
  end

  test "create_analysis responds with HTML redirect" do
    user = users(:one)
    repo = repositories(:one)
    sign_in user

    AnalysisDeep.stub :can_create_today?, true do
      AnalysisDeep.stub :user_can_create_today?, true do
        CreateDeepAnalysisJob.stub :perform_later, true do
          post create_analysis_repository_path(repo)
        end

        assert_redirected_to repository_path(repo)
        assert_match /started/, flash[:notice]
      end
    end
  end
end
