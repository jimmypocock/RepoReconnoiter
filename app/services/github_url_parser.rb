class GithubUrlParser
  #--------------------------------------
  # CUSTOM EXCEPTIONS
  #--------------------------------------

  class InvalidUrlError < StandardError; end

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
    if normalized.match?(%r{^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$})
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
    {
      owner: owner,
      name: name,
      full_name: "#{owner}/#{name}"
    }
  end

  def parse_url(input)
    # Add protocol if missing
    input = "https://#{input}" unless input.match?(%r{^https?://})

    begin
      uri = URI.parse(input)
    rescue URI::InvalidURIError
      raise InvalidUrlError, "Invalid URL format: #{input}"
    end

    # Ensure it's a GitHub URL
    unless uri.host&.match?(/github\.com$/i)
      raise InvalidUrlError, "Not a GitHub URL: #{input}"
    end

    # Extract path components
    path = uri.path
    return { owner: nil, name: nil, full_name: nil } if path.blank? || path == "/"

    # Remove leading/trailing slashes and split
    parts = path.gsub(%r{^/|/$}, "").split("/")

    # Need at least owner/repo
    if parts.length < 2
      raise InvalidUrlError, "URL must contain owner and repository name: #{input}"
    end

    owner = parts[0]
    name = parts[1]

    # Validate owner and name format
    unless owner.match?(/^[a-zA-Z0-9_-]+$/)
      raise InvalidUrlError, "Invalid owner format: #{owner}"
    end

    unless name.match?(/^[a-zA-Z0-9_.-]+$/)
      raise InvalidUrlError, "Invalid repository name format: #{name}"
    end

    { full_name: "#{owner}/#{name}", name:, owner: }
  end
end
