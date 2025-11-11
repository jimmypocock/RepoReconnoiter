module ApplicationHelper
  include Heroicon::ApplicationHelper

  # Pagy v43+ integrates frontend methods directly into the Pagy instance
  # No need to include Pagy::Frontend anymore

  # Validates and returns a GitHub URL, ensuring it's safe to render in views.
  # Returns nil if the URL is invalid or not a GitHub URL.
  # This prevents XSS attacks by explicitly validating the URL scheme and domain.
  def safe_github_url(url)
    return nil if url.blank?

    uri = URI.parse(url)
    return nil unless uri.scheme == "https"
    return nil unless uri.host == "github.com"

    url
  rescue URI::InvalidURIError
    nil
  end
end
