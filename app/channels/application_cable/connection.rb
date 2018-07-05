module ApplicationCable
  # base connection logic for websocket auth
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected

    def find_verified_user
      params = request.query_parameters

      uid = params['uid']
      token = params['access-token']
      client_id = params['client']

      user = User.find_by(uid: uid)

      if user && user.valid_token?(token, client_id)
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
