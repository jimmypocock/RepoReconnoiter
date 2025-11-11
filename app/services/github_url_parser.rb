class GithubUrlParser
  #--------------------------------------
  # CUSTOM EXCEPTIONS
  #--------------------------------------

  class InvalidUrlError < StandardError; end

  #--------------------------------------
  # CONSTANTS
  #--------------------------------------

  GITHUB_HOST_PATTERN = %r{github\.com$}i
  OWNER_FORMAT = %r{^[a-zA-Z0-9_-]+$}
  REPO_NAME_FORMAT = %r{^[a-zA-Z0-9_.-]+$}
  OWNER_REPO_FORMAT = %r{^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$}
  PROTOCOL_PATTERN = %r{^https?://}

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Parse a GitHub URL or owner/repo string into owner and name components
  # @param input [String] GitHub URL or "owner/repo" format
  # @return [Hash] { owner: String, name: String, full_name: String }
  # @raise [InvalidUrlError] if input cannot be parsed
  def parse(input)
    return { owner: nil, name: nil, full_name: nil } if input.blank?

    # Normalize input
    normalized = input.strip

    # Handle direct "owner/repo" format
    if normalized.match?(OWNER_REPO_FORMAT)
      return parse_owner_repo(normalized)
    end

    # Handle URL format
    parse_url(normalized)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    delegate :parse, to: :new
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def parse_owner_repo(input)
    owner, name = input.split("/", 2)
    validate_components!(owner, name)

    { full_name: "#{owner}/#{name}", name:, owner: }
  end

  def parse_url(input)
    # Add protocol if missing
    input = "https://#{input}" unless input.match?(PROTOCOL_PATTERN)

    uri = parse_uri(input)
    validate_github_host!(uri, input)

    owner, name = extract_path_components(uri, input)
    validate_components!(owner, name)

    { full_name: "#{owner}/#{name}", name:, owner: }
  end

  def parse_uri(input)
    URI.parse(input)
  rescue URI::InvalidURIError
    raise InvalidUrlError, "Invalid URL format: #{input}"
  end

  def validate_github_host!(uri, input)
    unless uri.host&.match?(GITHUB_HOST_PATTERN)
      raise InvalidUrlError, "Not a GitHub URL: #{input}"
    end
  end

  def extract_path_components(uri, input)
    path = uri.path
    return [ nil, nil ] if path.blank? || path == "/"

    # Remove leading/trailing slashes and split
    parts = path.gsub(%r{^/|/$}, "").split("/")

    # Need at least owner/repo
    if parts.length < 2
      raise InvalidUrlError, "URL must contain owner and repository name: #{input}"
    end

    [ parts[0], parts[1] ]
  end

  def validate_components!(owner, name)
    unless owner.match?(OWNER_FORMAT)
      raise InvalidUrlError, "Invalid owner format: #{owner}"
    end

    unless name.match?(REPO_NAME_FORMAT)
      raise InvalidUrlError, "Invalid repository name format: #{name}"
    end
  end
end
