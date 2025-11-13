# JSON Web Token encoding and decoding service
# Handles JWT creation and verification for API authentication
#
# Usage:
#   # Encode user ID into JWT
#   token = JsonWebToken.encode(user_id: 1)
#
#   # Decode and verify JWT
#   payload = JsonWebToken.decode(token)
#   user_id = payload[:user_id]
#
class JsonWebToken
  #--------------------------------------
  # CONSTANTS
  #--------------------------------------

  # JWT expiration time (24 hours)
  EXPIRATION_TIME = 24.hours

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Encode payload into JWT
    # @param payload [Hash] Data to encode (typically { user_id: 1 })
    # @param exp [Time] Optional custom expiration time
    # @return [String] Encoded JWT token
    def encode(payload, exp: EXPIRATION_TIME.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, secret_key, "HS256")
    end

    # Decode JWT and verify signature
    # @param token [String] JWT token to decode
    # @return [Hash] Decoded payload with symbolized keys
    # @raise [JWT::DecodeError] If token is invalid or expired
    def decode(token)
      decoded = JWT.decode(token, secret_key, true, { algorithm: "HS256" })
      HashWithIndifferentAccess.new(decoded[0])
    rescue JWT::ExpiredSignature, JWT::DecodeError => e
      raise JWT::DecodeError, "Invalid or expired token: #{e.message}"
    end

    private

    # Get secret key from Rails credentials
    # Falls back to SECRET_KEY_BASE in development/test
    def secret_key
      Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    end
  end
end
