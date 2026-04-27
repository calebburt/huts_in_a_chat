class ApplicationController < ActionController::Base
  # Skip CSRF only for token-authenticated API requests. Cookie-authenticated
  # requests — including JSON ones — must still present a valid token, so a
  # cross-origin form post can't ride a logged-in user's session.
  protect_from_forgery unless: -> { request.headers["X-Api-Key"].present? }

  helper_method :current_user
  before_action :set_current_user
  before_action :require_login

  def current_user
    Current.user
  end

  def set_current_user
    if request.headers["X-Api-Key"].present?
      Current.user = ApiKey.authenticate(request.headers["X-Api-Key"])
    else
      Current.user = User.find_by(id: session[:user_id])
    end
  end

  def require_login
    unless current_user
      respond_to do |format|
        format.html { redirect_to auth_login_path, alert: "Please log in to continue." }
        format.json { render json: { error: 403, message: "You must be logged in to view this action" }, status: 403 }
      end
    end
  end
end
