class RepositoryDeepAnalyzer
  attr_reader :ai, :broadcaster, :github

  def initialize(broadcaster: nil)
    @ai = OpenAi.new
    @github = Github.new
    @broadcaster = broadcaster
  end

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Performs deep analysis of a repository using gpt-4o
  # Fetches README, recent issues, and performs comprehensive analysis
  # Returns: Hash with all 5 analysis fields plus token counts
  def analyze(repository)
    # Step 1: Ensure README is fetched and cached
    broadcaster&.broadcast_step("fetching_readme", message: "Fetching README for #{repository.full_name}...")
    ensure_readme_fetched(repository)

    # Get README content
    readme_content = fetch_readme(repository)

    # Step 2: Fetch recent issues for analysis
    broadcaster&.broadcast_step("fetching_issues", message: "Fetching recent issues...")
    issues_data = fetch_recent_issues(repository)

    # Step 3: Run AI analysis
    broadcaster&.broadcast_step("running_analysis", message: "Running deep AI analysis with gpt-4o...")
    response = ai.chat(
      messages: [
        { role: "system", content: Prompter.render("repository_deep_analyzer_system") },
        { role: "user", content: Prompter.render("repository_deep_analyzer_build",
          repository: repository,
          readme_content: readme_content,
          issues_data: issues_data
        ) }
      ],
      model: "gpt-4o",
      temperature: 0.3,
      response_format: { type: "json_object" },
      track_as: "repository_deep_analysis"
    )

    # Validate output for suspicious patterns (defense-in-depth)
    raw_content = response.choices[0].message.content
    Prompter.validate_output(raw_content)

    content = JSON.parse(raw_content)

    {
      adoption_analysis: content["adoption_analysis"],
      input_tokens: response.usage.prompt_tokens,
      issues_analysis: content["issues_analysis"],
      maintenance_analysis: content["maintenance_analysis"],
      output_tokens: response.usage.completion_tokens,
      readme_analysis: content["readme_analysis"],
      security_analysis: content["security_analysis"]
    }
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    delegate :analyze, to: :new
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def ensure_readme_fetched(repository)
    # Skip if already fetched recently (within last hour)
    return if repository.readme_content.present? && repository.readme_fetched_at.present? && repository.readme_fetched_at > 1.hour.ago

    Rails.logger.info "Fetching README for #{repository.full_name}..."

    content = github.fetch_readme(repository.full_name)

    if content.present?
      repository.update!(
        readme_content: content,
        readme_fetched_at: Time.current,
        readme_length: content.length
      )
      Rails.logger.info "  ✅ README fetched (#{content.length} bytes)"
    else
      Rails.logger.warn "  ⚠️  No README found"
    end
  end

  def fetch_readme(repository)
    return "No README available" if repository.readme_content.blank?

    # Truncate if too long to avoid token limits
    max_length = 50_000 # ~12,500 tokens at 4 chars per token
    content = repository.readme_content

    if content.length > max_length
      "#{content[0...max_length]}\n\n[README truncated due to length...]"
    else
      content
    end
  end

  def fetch_recent_issues(repository)
    # Fetch last 30 issues (mix of open and closed)
    issues = github.fetch_issues(repository.full_name, state: "all", per_page: 30)

    return "No issues available" if issues.empty?

    # Format issues for analysis
    issues.map do |issue|
      {
        title: issue.title,
        state: issue.state,
        created_at: issue.created_at,
        comments: issue.comments,
        labels: issue.labels.map(&:name),
        is_pull_request: !issue.pull_request.nil?
      }
    end
  end
end
