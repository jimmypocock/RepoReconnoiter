require_relative "boot"

# Load individual Rails components instead of "rails/all"
# This allows us to skip features we don't need (Action Mailbox, Active Storage)
require "rails"

# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"  # ❌ Disabled - no file uploads
require "action_controller/railtie"
require "action_mailer/railtie"  # ✅ Enabled - not configured yet, but ready for future use
# require "action_mailbox/engine"  # ❌ Disabled - no incoming email processing
# require "action_text/engine"  # ❌ Disabled - no rich text editing (depends on Active Storage)
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Require custom middleware (must be explicit since lib/middleware is excluded from autoload)
require_relative "../lib/middleware/request_size_limiter"

module RepoReconnoiter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks middleware])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Enable Rack::Attack for rate limiting
    config.middleware.use Rack::Attack

    # Request size limits (prevent large payload attacks)
    # Middleware class: lib/middleware/request_size_limiter.rb
    config.middleware.use RequestSizeLimiter

    #--------------------------------------
    # SECURITY HEADERS (OWASP Recommendations)
    #--------------------------------------
    # These headers are applied at Rack middleware level (before routing)
    # More performant than controller-level headers
    # See: https://owasp.org/www-project-secure-headers/

    config.action_dispatch.default_headers.merge!(
      {
        # Prevent clickjacking attacks (deny all framing)
        "X-Frame-Options" => "DENY",

        # Prevent MIME type sniffing (force browser to respect Content-Type)
        "X-Content-Type-Options" => "nosniff",

        # Enable browser's XSS filter (legacy, CSP is primary defense)
        "X-XSS-Protection" => "1; mode=block",

        # Control referrer information sent to external sites
        "Referrer-Policy" => "strict-origin-when-cross-origin",

        # Permissions Policy - disable unnecessary browser features
        "Permissions-Policy" => [
          "geolocation=()",      # Block geolocation API
          "microphone=()",       # Block microphone access
          "camera=()",           # Block camera access
          "payment=()",          # Block payment API
          "usb=()",              # Block USB access
          "interest-cohort=()"   # Block FLoC tracking (privacy)
        ].join(", ")
      }
    )
  end
end
