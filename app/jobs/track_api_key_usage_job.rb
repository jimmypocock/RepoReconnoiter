class TrackApiKeyUsageJob < ApplicationJob
  queue_as :default

  # Track API key usage (last_used_at, request_count)
  # @param api_key_id [Integer] The ID of the ApiKey to track
  def perform(api_key_id)
    api_key = ApiKey.find_by(id: api_key_id)
    return unless api_key

    api_key.track_usage!
  end
end
