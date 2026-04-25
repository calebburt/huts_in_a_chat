class AuthController < ApplicationController
  skip_before_action :require_login, except: [ :new, :create, :created ]
  def new
    @user = User.new
    @token = InvitationToken.new
  end

  def create
    user = User.new(confirmed: false)
    user.save(validate: false)
    logger.error user.errors.full_messages unless user.persisted?
    @token = InvitationToken.create(token: SecureRandom.hex(10), expires: 15.minutes.from_now, user: user)
    redirect_to auth_created_path(token: @token.token)
  end

  def created
    @token = InvitationToken.find_by(token: params[:token])
    unless @token
      redirect_to auth_login_path, alert: "Invalid token."
    end
  end

  def accept
    logger.error "accepting token"
    @token = InvitationToken.find_by(token: params[:token])
    if @token && @token.expires > Time.current
      render
    else
      redirect_to auth_login_path, alert: "Invalid or expired token."
    end
  end

  def signup
    token = InvitationToken.find_by(token: params[:user][:token])
    if token && token.expires > Time.current
      user = token.user
      user.name = params[:user][:name]
      user.email = params[:user][:email]
      user.password = params[:user][:password]
      user.confirmed = true
      if user.save
        session[:user_id] = user.id
        token.delete
        redirect_to root_path, notice: "Signup successful. You are now logged in."
      else
        logger.error user.errors
        redirect_to auth_accept_path(token: token.token), alert: "Failed to create account. Please try again."
      end
    else
      redirect_to root_path, alert: "Invalid or expired token."
    end
  end

  def login
    if request.post?
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        session[:user_id] = user.id
        redirect_to root_path
      else
        redirect_to auth_login_path, alert: "Incorrect username or password."
      end
    end
  end

  def logout
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out successfully."
  end

  def push_subscriptions
    if subscription = PushSubscription.find_by(push_subscription_params)
      subscription.touch
    else
      PushSubscription.create! push_subscription_params.merge(user: current_user)
    end

    head :ok
  end

  private
  def push_subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key)
  end
end
