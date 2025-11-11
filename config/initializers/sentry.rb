# frozen_string_literal: true

# Skip Sentry initialization in test environment
return if Rails.env.test?

Sentry.init do |config|
  # config.breadcrumbs_logger = [:active_support_logger]
  # config.dsn = ENV['SENTRY_DSN']
  # config.traces_sample_rate = 1.0
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Set traces_sample_rate to capture 10% of transactions for performance monitoring
  # Set to 0.0 to disable performance monitoring entirely
  config.traces_sample_rate = Rails.env.production? ? 0.1 : 1.0

  # Capture user data (IP, request headers) for debugging
  # See https://docs.sentry.io/platforms/ruby/data-management/data-collected/
  config.send_default_pii = true

  # Set environment
  config.environment = Rails.env

  # Filter sensitive data from being sent to Sentry
  config.before_send = lambda do |event, hint|
    # Don't send events in test environment
    return nil if Rails.env.test?

    # Filter out sensitive params
    if event.request
      event.request.data&.delete("password")
      event.request.data&.delete("password_confirmation")
    end

    event
  end
end
