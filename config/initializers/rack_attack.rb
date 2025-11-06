# Rack::Attack configuration for rate limiting
#
# Documentation: https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###

  # Use Rails.cache for storing rate limit data
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Rules ###

  # Throttle comparison creation by authenticated user
  # Limit: 25 requests per 24 hours (allows buffer over the 20/day business logic limit)
  throttle("comparisons/user", limit: 25, period: 24.hours) do |req|
    if req.path == "/comparisons" && req.post?
      # Extract user_id from Devise session
      req.env["warden"]&.user&.id
    end
  end

  # Throttle comparison creation by IP address (for anonymous/malicious actors)
  # Limit: 5 requests per 24 hours
  throttle("comparisons/ip", limit: 5, period: 24.hours) do |req|
    if req.path == "/comparisons" && req.post?
      req.ip
    end
  end

  # Throttle OAuth callback attempts (prevent brute force)
  # Limit: 10 requests per 5 minutes
  throttle("oauth/ip", limit: 10, period: 5.minutes) do |req|
    if req.path.include?("/users/auth/github") && req.post?
      req.ip
    end
  end

  ### Custom Responses ###

  # Customize response when throttled
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "Content-Type" => "text/html",
      "Retry-After" => (match_data[:period] - (now % match_data[:period])).to_s
    }

    message = if env["rack.attack.matched"] == "comparisons/user"
      "You've reached your daily limit. Try again tomorrow!"
    elsif env["rack.attack.matched"] == "comparisons/ip"
      "Too many requests. Please try again later."
    else
      "Rate limit exceeded. Please try again later."
    end

    [ 429, headers, [ message ] ]
  end

  ### Safelist ###

  # Always allow requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1" if Rails.env.development?
  end
end
