# frozen_string_literal: true

# Only enable Sentry in production
return unless Rails.env.production?

Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Capture 10% of transactions for performance monitoring
  config.traces_sample_rate = 0.1

  # Capture user data (IP, request headers) for debugging
  # See https://docs.sentry.io/platforms/ruby/data-management/data-collected/
  config.send_default_pii = true

  # Set environment
  config.environment = Rails.env

  # Filter sensitive data from being sent to Sentry
  config.before_send = lambda do |event, hint|
    # Filter out sensitive params
    if event.request
      event.request.data&.delete("password")
      event.request.data&.delete("password_confirmation")
    end

    event
  end
end
