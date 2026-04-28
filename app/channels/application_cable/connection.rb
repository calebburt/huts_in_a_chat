module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      api_key_user || session_user || reject_unauthorized_connection
    end

    def api_key_user
      key = request.headers["X-Api-Key"].presence || request.params[:api_key].presence
      key && ApiKey.authenticate(key)
    end

    def session_user
      session_key = Rails.application.config.session_options[:key] ||
                    "_#{Rails.application.class.module_parent_name.underscore}_session"
      session = cookies.encrypted[session_key] || {}
      user_id = session["user_id"] || session[:user_id]
      User.find_by(id: user_id)
    end
  end
end
