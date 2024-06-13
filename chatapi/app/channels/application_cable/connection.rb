module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      params = request.query_parameters()
      uid = params["uid"]
      self.current_user = find_verified_user uid
      # reject_unauthorized_connection unless find_verified_user(access_token, uid, client)
      # logger.info "ActionCable #{current_user.email}"
    end

    private

    def find_verified_user uid

      user = User.find_by(email: uid)
      unless user.nil?
        user
      else
        reject_unauthorized_connection
      end
      # http://www.rubydoc.info/gems/devise_token_auth/0.1.38/DeviseTokenAuth%2FConcerns%2FUser:valid_token%3F
      # if user && user.valid_token?(token, client_id)
      #   user
      # else                 
      #   reject_unauthorized_connection
      # end
    end
  end
end
