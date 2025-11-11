module ApplicationHelper
  include Heroicon::ApplicationHelper

  # Pagy v43+ integrates frontend methods directly into the Pagy instance
  # No need to include Pagy::Frontend anymore

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Returns number of comparisons created today by the given user
  def comparisons_created_today(user)
    return 0 unless user

    Comparison.where(user_id: user.id)
              .where("created_at >= ?", Time.current.beginning_of_day)
              .count
  end

  # Returns number of comparisons remaining for user (out of 25/day limit)
  # Admins have unlimited comparisons
  def comparisons_remaining(user)
    return "Unlimited" if user&.admin?
    return 25 if user.nil?

    25 - comparisons_created_today(user)
  end

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
