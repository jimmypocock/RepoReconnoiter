# Rack::Attack configuration for rate limiting
#
# Documentation: https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###

  # Use Rails.cache (Solid Cache in production - persistent across deploys/servers)
  # MemoryStore works for development but NOT production with multiple servers
  Rack::Attack.cache.store = Rails.cache

  ### Throttle Rules ###

  # Throttle API GET requests (prevent scraping/abuse)
  # Limit: 100 requests per hour per IP
  throttle("api/ip", limit: 100, period: 1.hour) do |req|
    if req.path.start_with?("/api/v1/")
      req.ip
    end
  end

  # Stricter limit for unauthenticated API users
  # Limit: 20 requests per 10 minutes per IP (prevents rapid scraping)
  throttle("api/burst", limit: 20, period: 10.minutes) do |req|
    if req.path.start_with?("/api/v1/") && !req.env["warden"]&.user
      req.ip
    end
  end

  # Throttle comparison creation by authenticated user
  # Limit: 25 requests per 24 hours (allows buffer over the 20/day business logic limit)
  # Admins are exempt from throttling
  throttle("comparisons/user", limit: 25, period: 24.hours) do |req|
    if req.path == "/comparisons" && req.post?
      user = req.env["warden"]&.user
      user&.id unless user&.admin?
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

  ### Blocklist ###

  # Block specific IPs (add abusive IPs here)
  # Example: blocklist("1.2.3.4") { |req| req.ip == "1.2.3.4" }
  # Can also use ENV["BLOCKED_IPS"] in production
  blocklist_ips = ENV.fetch("BLOCKED_IPS", "").split(",").map(&:strip)
  blocklist("blocked-ips") do |req|
    blocklist_ips.include?(req.ip)
  end if blocklist_ips.any?

  ### Custom Responses ###

  # Return JSON for API requests, HTML for web requests
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = (match_data[:period] - (now % match_data[:period])).to_s

    # Determine if this is an API request
    is_api = env["PATH_INFO"]&.start_with?("/api/")

    headers = {
      "Content-Type" => is_api ? "application/json" : "text/html",
      "Retry-After" => retry_after
    }

    message = case env["rack.attack.matched"]
    when "comparisons/user"
      "You've reached your daily limit. Try again tomorrow!"
    when "api/ip", "api/burst"
      "API rate limit exceeded. Try again later."
    else
      "Rate limit exceeded. Please try again later."
    end

    body = if is_api
      { error: { message: message, retry_after: retry_after.to_i } }.to_json
    else
      message
    end

    [ 429, headers, [ body ] ]
  end

  # Customize response when blocklisted
  self.blocklisted_responder = lambda do |_env|
    [ 403, { "Content-Type" => "text/html" }, [ "Forbidden" ] ]
  end

  ### Safelist ###

  # Always allow requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1" if Rails.env.development?
  end

  # Allow trusted clients (Next.js server) to bypass rate limits
  # These clients send API key in Authorization header
  # Keys are managed in the database (ApiKey model)
  safelist("trusted-client") do |req|
    # Check for valid API key in Authorization header
    # Format: "Bearer <API_KEY>"
    auth_header = req.env["HTTP_AUTHORIZATION"]
    next false unless auth_header&.start_with?("Bearer ")

    raw_key = auth_header.sub("Bearer ", "")

    # Authenticate via database (all environments)
    api_key_record = ApiKey.authenticate(raw_key)
    if api_key_record
      # Track usage in background to avoid slowing down request
      ApiKeyUsageTracker.track_async(api_key_record.id)
      true
    else
      # Fallback to ENV var ONLY in development/test (never production)
      # This allows you to use ENV vars in .env file before creating database keys
      if Rails.env.development? || Rails.env.test?
        trusted_api_keys = ENV.fetch("TRUSTED_API_KEYS", "").split(",").map(&:strip)
        trusted_api_keys.include?(raw_key)
      else
        # Production: Database only, no ENV var fallback
        false
      end
    end
  end
end
