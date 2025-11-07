require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Include Warden test helpers for authentication
  include Warden::Test::Helpers

  def setup
    super
    Warden.test_mode!
  end

  def teardown
    super
    Warden.test_reset!
  end

  # Authentication helper for system tests
  # Uses Warden to directly sign in user, bypassing OAuth flow
  def sign_in(user)
    login_as(user, scope: :user)
  end

  # Ensure completely clean unauthenticated state
  # Resets both browser session (cookies, localStorage) and Warden authentication
  # Call this at the start of tests that expect unauthenticated users
  def ensure_unauthenticated
    Capybara.reset_sessions!  # Reset browser session (fixes CI test isolation)
    Warden.test_reset!         # Reset Warden authentication state
  end
end
