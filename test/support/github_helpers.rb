module GithubHelpers
  # Stub GitHub API calls to prevent hitting real API in tests
  def stub_github_search
    # Return realistic repository data
    mock_repo = OpenStruct.new(
      id: 12345,
      node_id: "MDEwOlJlcG9zaXRvcnkxMjM0NQ==",
      name: "test-repo",
      full_name: "test/test-repo",
      owner: OpenStruct.new(
        login: "test",
        avatar_url: "https://avatars.githubusercontent.com/u/123",
        type: "User"
      ),
      html_url: "https://github.com/test/test-repo",
      description: "A test repository",
      fork: false,
      created_at: 1.year.ago,
      updated_at: 1.week.ago,
      pushed_at: 1.day.ago,
      homepage: "https://example.com",
      size: 1000,
      stargazers_count: 100,
      watchers_count: 100,
      language: "Ruby",
      forks_count: 10,
      open_issues_count: 5,
      default_branch: "main",
      score: 1.0,
      topics: [ "rails", "ruby" ],
      visibility: "public",
      archived: false,
      disabled: false,
      license: OpenStruct.new(key: "mit")
    )

    mock_result = OpenStruct.new(items: [ mock_repo ])

    Github.class_eval do
      define_method(:search) do |*args, **kwargs|
        mock_result
      end
    end
  end
end
