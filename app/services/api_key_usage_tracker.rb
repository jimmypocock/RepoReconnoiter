# API Key Usage Tracker
# Tracks API key usage asynchronously to avoid slowing down requests
#
class ApiKeyUsageTracker
  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Track API key usage asynchronously (via background job)
    # @param api_key_id [Integer] The ID of the ApiKey to track
    def track_async(api_key_id)
      TrackApiKeyUsageJob.perform_later(api_key_id)
    end

    # Track API key usage synchronously (for testing or critical paths)
    # @param api_key_id [Integer] The ID of the ApiKey to track
    def track_sync(api_key_id)
      api_key = ApiKey.find_by(id: api_key_id)
      return unless api_key

      api_key.track_usage!
    end
  end
end
