class AuthController < ApplicationController
  skip_before_action :require_login, except: [ :new, :create, :created ]

  rate_limit to: 10, within: 1.hour, only: :create,
             with: -> { redirect_to auth_new_path, alert: "Too many invitations created. Try again later." }
  rate_limit to: 10, within: 5.minutes, only: :login,
             with: -> { redirect_to auth_login_path, alert: "Too many attempts. Try again in a few minutes." }
  rate_limit to: 10, within: 1.hour, only: :signup,
             with: -> { redirect_to root_path, alert: "Too many signup attempts. Try again later." }

  def new
    @user = User.new
    @token = InvitationToken.new
  end

  def create
    user = User.new(confirmed: false)
    user.save(validate: false)
    logger.error user.errors.full_messages unless user.persisted?
    @token = InvitationToken.create(token: SecureRandom.hex(16), expires: 15.minutes.from_now, user: user)
    redirect_to auth_created_path(token: @token.token)
  end

  def created
    @token = InvitationToken.find_by(token: params[:token])
    redirect_to auth_login_path, alert: "Invalid token." unless @token
  end

  def accept
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
      user.email = params[:user][:email].to_s.downcase
      user.password = params[:user][:password]
      user.confirmed = true
      if user.save
        reset_session
        session[:user_id] = user.id
        token.delete
        redirect_to root_path, notice: "Signup successful. You are now logged in."
      else
        logger.error user.errors.full_messages
        redirect_to auth_accept_path(token: token.token), alert: "Failed to create account: #{user.errors.full_messages.join(', ')}"
      end
    else
      redirect_to root_path, alert: "Invalid or expired token."
    end
  end

  def login
    if request.post?
      user = User.find_by(email: params[:email].to_s.downcase)
      if user&.authenticate(params[:password])
        reset_session
        session[:user_id] = user.id
        redirect_to root_path
      else
        redirect_to auth_login_path, alert: "Incorrect username or password."
      end
    end
  end

  def logout
    reset_session
    redirect_to root_path, notice: "Logged out successfully."
  end

  def push_subscriptions
    subscription = current_user.push_subscriptions.find_by(endpoint: push_subscription_params[:endpoint])
    if subscription
      subscription.update(push_subscription_params)
    else
      current_user.push_subscriptions.create!(push_subscription_params)
    end

    head :ok
  end

  private
  def push_subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key)
  end
end
