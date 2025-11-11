class RepositoryDecorator < SimpleDelegator
  # Delegates all repository methods to the wrapped model
  # Usage: RepositoryDecorator.new(repository)

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Returns safe GitHub URL for rendering in views
  # Returns nil if invalid or not a GitHub URL
  def safe_github_url
    return nil if html_url.blank?

    uri = URI.parse(html_url)
    return nil unless uri.scheme == "https"
    return nil unless uri.host == "github.com"

    html_url
  rescue URI::InvalidURIError
    nil
  end

  # Returns formatted star count (e.g., "13.2k")
  def formatted_stars
    return "0" if stargazers_count.zero?

    if stargazers_count >= 1000
      "#{(stargazers_count / 1000.0).round(1)}k"
    else
      stargazers_count.to_s
    end
  end

  # Returns formatted fork count
  def formatted_forks
    return "0" if forks_count.zero?

    if forks_count >= 1000
      "#{(forks_count / 1000.0).round(1)}k"
    else
      forks_count.to_s
    end
  end

  # Returns language with fallback
  def language_display
    language.presence || "N/A"
  end
end
