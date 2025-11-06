# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# Based on OWASP recommendations and Rails 8 best practices (2025)
# Configured for Hotwire Turbo + Tailwind CSS

Rails.application.configure do
  config.content_security_policy do |policy|
    # Default to same-origin and HTTPS only
    policy.default_src :self, :https

    # Allow fonts from same origin, HTTPS CDNs, and data URIs
    policy.font_src :self, :https, :data

    # Allow images from same origin, HTTPS (includes GitHub avatars), data URIs, and blobs
    policy.img_src :self, :https, :data, :blob

    # Block all object/embed/applet (Flash, Java, etc.)
    policy.object_src :none

    # Scripts: self + nonce for inline Turbo scripts + Microsoft Clarity
    # Note: Turbo requires some inline event handlers, nonce handles this safely
    # Note: Clarity loads from both www.clarity.ms (tag) and scripts.clarity.ms (main library)
    policy.script_src :self, "https://www.clarity.ms", "https://scripts.clarity.ms"

    # Styles: self + nonce for inline Tailwind styles
    # Note: Tailwind may inject some inline styles, nonce handles this safely
    policy.style_src :self

    # Allow AJAX/WebSocket connections to same origin and HTTPS (for Turbo, API calls, Clarity)
    policy.connect_src :self, :https, "https://*.clarity.ms"

    # Block framing except from same origin (clickjacking prevention)
    policy.frame_ancestors :self

    # Base URI restriction (prevents base tag injection)
    policy.base_uri :self

    # Form action restriction (prevent form hijacking)
    policy.form_action :self

    # Upgrade insecure requests (HTTP -> HTTPS)
    policy.upgrade_insecure_requests true if Rails.env.production?
  end

  # Generate nonces for inline scripts/styles using SecureRandom
  # Session IDs are NOT suitable for CSP nonces (session fixation risk)
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }

  # Apply nonces to script-src and style-src directives
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Automatically add nonce to javascript_tag, javascript_include_tag, stylesheet_link_tag
  # This makes Turbo inline scripts work seamlessly
  config.content_security_policy_nonce_auto = true

  # Enforce CSP (not report-only) - Microsoft Clarity is CSP-friendly
  # If you see violations in console, check the CSP configuration above
  # config.content_security_policy_report_only = true
end
