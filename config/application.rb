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
# require "action_mailer/railtie"  # ❌ Disabled - no outgoing emails (yet)
# require "action_mailbox/engine"  # ❌ Disabled - no incoming email processing
# require "action_text/engine"  # ❌ Disabled - no rich text editing (depends on Active Storage)
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RepoReconnoiter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Enable Rack::Attack for rate limiting
    config.middleware.use Rack::Attack
  end
end
