module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Get user from session cookie (Devise sets this)
      if verified_user = User.find_by(id: cookies.encrypted[:user_id])
        verified_user
      else
        # Allow anonymous connections for progress updates
        # We'll use session_id for stream isolation instead
        nil
      end
    end
  end
end
