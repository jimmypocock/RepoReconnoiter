require "test_helper"

class RepositoryTest < ActiveSupport::TestCase
  #--------------------------------------
  # DEDUPLICATION: GitHub API Sync Logic
  #--------------------------------------

  test "from_github_api creates new repository with GitHub data" do
    github_data = build_github_api_response(id: 99999, full_name: "test/repo", stars: 100)

    repo = Repository.from_github_api(github_data)

    assert repo.new_record?, "Should be a new record"
    assert_equal 99999, repo.github_id
    assert_equal "test/repo", repo.full_name
    assert_equal 100, repo.stargazers_count
    assert_equal 0, repo.fetch_count, "New repo should have fetch_count of 0"
  end

  test "from_github_api finds existing repository by github_id" do
    # Create existing repo
    existing_repo = Repository.create!(
      github_id: 12345,
      node_id: "MDEwOlJlcG9zaXRvcnkxMjM0NQ==",
      full_name: "old/name",
      name: "name",
      html_url: "https://github.com/old/name",
      stargazers_count: 50,
      fetch_count: 5
    )

    # Fetch same repo with updated data
    github_data = build_github_api_response(
      id: 12345,
      full_name: "new/name",
      stars: 150
    )

    repo = Repository.from_github_api(github_data)

    # Should find existing repo, not create new one
    assert_equal existing_repo.id, repo.id
    assert repo.persisted?, "Should be existing record"

    # Data should be updated
    assert_equal "new/name", repo.full_name
    assert_equal 150, repo.stargazers_count
  end

  test "from_github_api prevents duplicate repositories" do
    github_data = build_github_api_response(id: 99999, full_name: "test/repo")

    # First fetch
    repo1 = Repository.from_github_api(github_data)
    repo1.save!

    # Second fetch of same repo
    repo2 = Repository.from_github_api(github_data)

    # Should be the same record
    assert_equal repo1.id, repo2.id
    assert_equal 1, Repository.where(github_id: 99999).count, "Should only have one record"
  end

  test "from_github_api increments fetch_count for existing repos" do
    # Create existing repo
    existing_repo = Repository.create!(
      github_id: 12345,
      node_id: "MDEwOlJlcG9zaXRvcnkxMjM0NQ==",
      full_name: "test/repo",
      name: "repo",
      html_url: "https://github.com/test/repo",
      fetch_count: 3
    )

    github_data = build_github_api_response(id: 12345)

    repo = Repository.from_github_api(github_data)

    # fetch_count should increment
    assert_equal 4, repo.fetch_count, "Should increment fetch_count on re-fetch"
  end

  test "from_github_api does not increment fetch_count for new repos" do
    github_data = build_github_api_response(id: 99999)

    repo = Repository.from_github_api(github_data)

    assert_equal 0, repo.fetch_count, "New repos should start at fetch_count 0"
  end

  test "from_github_api handles missing optional fields with defaults" do
    github_data = {
      id: 99999,
      node_id: "MDEwOlJlcG9zaXRvcnk5OTk5OQ==",
      full_name: "test/repo",
      name: "repo",
      html_url: "https://github.com/test/repo",
      created_at: "2023-01-01T00:00:00Z",
      updated_at: "2023-01-01T00:00:00Z",
      pushed_at: "2023-01-01T00:00:00Z",
      owner: {
        login: "test",
        avatar_url: "https://example.com/avatar.jpg",
        type: "User"
      }
      # Missing: description, language, license, homepage, etc.
    }

    repo = Repository.from_github_api(github_data)

    # Should use defaults
    assert_equal 0, repo.stargazers_count
    assert_equal 0, repo.forks_count
    assert_equal [], repo.topics
    assert_equal false, repo.is_fork
    assert_equal false, repo.archived
    assert_equal "public", repo.visibility
  end

  test "from_github_api extracts nested owner data correctly" do
    github_data = build_github_api_response(
      id: 99999,
      owner: {
        login: "testuser",
        avatar_url: "https://example.com/avatar.jpg",
        type: "Organization"
      }
    )

    repo = Repository.from_github_api(github_data)

    assert_equal "testuser", repo.owner_login
    assert_equal "https://example.com/avatar.jpg", repo.owner_avatar_url
    assert_equal "Organization", repo.owner_type
  end

  #--------------------------------------
  # ANALYSIS: Current Analysis Retrieval
  #--------------------------------------

  test "analysis_current returns current analysis" do
    repo = repositories(:no_analyses)

    # Create a current analysis
    current_analysis = repo.analyses.create!(
      type: "Analysis",
      model_used: "gpt-5-mini",
      summary: "Current analysis",
      is_current: true
    )

    # Create old analysis
    repo.analyses.create!(
      type: "Analysis",
      model_used: "gpt-5-mini",
      summary: "Old analysis",
      is_current: false
    )

    assert_equal current_analysis.id, repo.analysis_current.id
    assert_equal "Current analysis", repo.analysis_current.summary
  end

  test "analysis_current returns nil when no current analysis exists" do
    repo = repositories(:no_analyses)

    # Create only non-current analysis
    repo.analyses.create!(
      type: "Analysis",
      model_used: "gpt-5-mini",
      summary: "Old analysis",
      is_current: false
    )

    assert_nil repo.analysis_current
  end

  test "analysis_current ignores deep analyses" do
    repo = repositories(:no_analyses)

    # Create current deep analysis (should be ignored)
    repo.analyses.create!(
      type: "AnalysisDeep",
      model_used: "gpt-5",
      summary: "Deep analysis",
      is_current: true
    )

    assert_nil repo.analysis_current
  end

  #--------------------------------------
  # ANALYSIS: Needs Re-Analysis Logic
  #--------------------------------------

  test "needs_analysis? returns true when never analyzed" do
    repo = repositories(:no_analyses)
    repo.update!(last_analyzed_at: nil)

    assert repo.needs_analysis?
  end

  test "needs_analysis? returns true when last analyzed over 7 days ago" do
    repo = repositories(:no_analyses)
    repo.update!(last_analyzed_at: 8.days.ago)

    assert repo.needs_analysis?
  end

  test "needs_analysis? returns false when recently analyzed" do
    repo = repositories(:no_analyses)
    repo.update!(last_analyzed_at: 3.days.ago)

    refute repo.needs_analysis?
  end

  test "needs_analysis? returns false when analyzed exactly 6 days ago" do
    repo = repositories(:no_analyses)
    repo.update!(last_analyzed_at: 6.days.ago)

    refute repo.needs_analysis?
  end

  private

  def build_github_api_response(id:, full_name: "test/repo", stars: 100, owner: nil)
    {
      id: id,
      node_id: "MDEwOlJlcG9zaXRvcnk#{id}",
      full_name: full_name,
      name: full_name.split("/").last,
      description: "Test repository",
      html_url: "https://github.com/#{full_name}",
      homepage: "https://example.com",
      clone_url: "https://github.com/#{full_name}.git",
      language: "Ruby",
      size: 1000,
      stargazers_count: stars,
      forks_count: 10,
      open_issues_count: 5,
      watchers_count: stars,
      topics: [ "ruby", "rails" ],
      default_branch: "main",
      fork: false,
      archived: false,
      disabled: false,
      visibility: "public",
      created_at: "2023-01-01T00:00:00Z",
      updated_at: "2023-01-01T00:00:00Z",
      pushed_at: "2023-01-01T00:00:00Z",
      owner: owner || {
        login: "testuser",
        avatar_url: "https://example.com/avatar.jpg",
        type: "User"
      },
      license: {
        key: "mit",
        name: "MIT License"
      }
    }
  end
end
