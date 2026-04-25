class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  helper_method :current_user
  before_action :set_current_user
  before_action :require_login

  def current_user
    Current.user
  end

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
  end

  def require_login
    unless current_user
      redirect_to auth_login_path, alert: "Please log in to continue."
    end
  end
end
