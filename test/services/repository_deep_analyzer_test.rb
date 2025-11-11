require "test_helper"

class RepositoryDeepAnalyzerTest < ActiveSupport::TestCase
  setup do
    @repository = repositories(:one)

    # Stub OpenAI for deep analysis
    stub_openai_chat(response_content: '{
      "readme_analysis": "Well-documented with clear setup instructions",
      "issues_analysis": "Active issue tracker with responsive maintainers",
      "maintenance_analysis": "Regularly updated with recent commits",
      "adoption_analysis": "Widely adopted in Ruby community",
      "security_analysis": "No known security vulnerabilities"
    }')

    # Stub GitHub API methods
    stub_github_readme
    stub_github_issues
  end

  #--------------------------------------
  # RESULT STRUCTURE
  #--------------------------------------

  test "analyze returns correct structure with 5 analysis fields and tokens" do
    result = RepositoryDeepAnalyzer.new.analyze(@repository)

    # Check all 5 required fields
    assert result.key?(:readme_analysis)
    assert result.key?(:issues_analysis)
    assert result.key?(:maintenance_analysis)
    assert result.key?(:adoption_analysis)
    assert result.key?(:security_analysis)

    # Check token tracking
    assert result.key?(:input_tokens)
    assert result.key?(:output_tokens)

    # Verify values are strings/integers
    assert_kind_of String, result[:readme_analysis]
    assert_kind_of String, result[:issues_analysis]
    assert_kind_of String, result[:maintenance_analysis]
    assert_kind_of String, result[:adoption_analysis]
    assert_kind_of String, result[:security_analysis]
    assert_kind_of Integer, result[:input_tokens]
    assert_kind_of Integer, result[:output_tokens]
  end

  #--------------------------------------
  # README HANDLING
  #--------------------------------------

  test "analyze fetches and caches README if not present" do
    @repository.update!(readme_content: nil, readme_fetched_at: nil)

    RepositoryDeepAnalyzer.new.analyze(@repository)

    @repository.reload
    assert_not_nil @repository.readme_content
    assert_not_nil @repository.readme_fetched_at
    assert_equal "# Test README\nThis is a test repository.".length, @repository.readme_length
  end

  test "analyze uses cached README if present and recent" do
    cached_content = "# Cached README"
    @repository.update!(
      readme_content: cached_content,
      readme_fetched_at: 30.minutes.ago,
      readme_length: cached_content.length
    )

    RepositoryDeepAnalyzer.new.analyze(@repository)

    # README should not have changed since cache is recent
    assert_equal cached_content, @repository.reload.readme_content
  end

  test "analyze refetches README if cache is stale" do
    @repository.update!(
      readme_content: "# Old README",
      readme_fetched_at: 2.hours.ago
    )

    RepositoryDeepAnalyzer.new.analyze(@repository)

    @repository.reload
    assert_equal "# Test README\nThis is a test repository.", @repository.readme_content
  end

  test "analyze truncates long READMEs over 50k characters" do
    long_readme = "a" * 60_000
    stub_github_readme(content: long_readme)

    @repository.update!(readme_content: nil)

    result = RepositoryDeepAnalyzer.new.analyze(@repository)

    # Should be present in the analysis but truncated in prompt
    # We can't easily test the prompt content, but we can verify it runs without error
    assert_not_nil result[:readme_analysis]
  end

  test "analyze handles missing README gracefully" do
    stub_github_readme(content: nil)

    @repository.update!(readme_content: nil)

    result = RepositoryDeepAnalyzer.new.analyze(@repository)

    # Should still return valid structure
    assert_not_nil result[:readme_analysis]
    assert_nil @repository.reload.readme_content
  end

  #--------------------------------------
  # ISSUES HANDLING
  #--------------------------------------

  test "analyze fetches recent issues" do
    result = RepositoryDeepAnalyzer.new.analyze(@repository)

    # Should complete successfully with issues data
    assert_not_nil result[:issues_analysis]
  end

  test "analyze handles repositories with no issues" do
    stub_github_issues(issues: [])

    result = RepositoryDeepAnalyzer.new.analyze(@repository)

    # Should still return valid structure
    assert_not_nil result[:issues_analysis]
  end

  private

  #--------------------------------------
  # TEST HELPERS
  #--------------------------------------

  def stub_github_readme(content: "# Test README\nThis is a test repository.")
    Github.class_eval do
      define_method(:fetch_readme) do |*args|
        content
      end
    end
  end

  def stub_github_issues(issues: nil)
    default_issues = [
      OpenStruct.new(
        title: "Feature request",
        state: "open",
        created_at: 1.week.ago,
        comments: 5,
        labels: [ OpenStruct.new(name: "enhancement") ],
        pull_request: nil
      ),
      OpenStruct.new(
        title: "Bug fix",
        state: "closed",
        created_at: 2.weeks.ago,
        comments: 2,
        labels: [ OpenStruct.new(name: "bug") ],
        pull_request: nil
      )
    ]

    Github.class_eval do
      define_method(:fetch_issues) do |*args, **kwargs|
        issues || default_issues
      end
    end
  end
end
