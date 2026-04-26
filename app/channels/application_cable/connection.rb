module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session_key = Rails.application.config.session_options[:key] ||
                    "_#{Rails.application.class.module_parent_name.underscore}_session"
      session = cookies.encrypted[session_key] || {}
      user_id = session["user_id"] || session[:user_id]
      User.find_by(id: user_id) || reject_unauthorized_connection
    end
  end
end
