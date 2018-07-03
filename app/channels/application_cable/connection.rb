module ApplicationCable
  # base connection logic for websocket auth
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected

    def find_verified_user
      uid = request.headers['Uid']
      token = request.headers['Access-Token']
      client_id = request.headers['Client']

      user = User.find_by(uid: uid)

      if user && user.valid_token?(token, client_id)
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
