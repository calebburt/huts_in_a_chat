class ApiController < ApplicationController
  skip_before_action :require_login, only: [ :create, :signup ]
  skip_before_action :verify_authenticity_token, only: [ :create, :signup ]

  rate_limit to: 10, within: 5.minutes, only: :create,
             with: -> { render_too_many_requests }
  rate_limit to: 10, within: 1.hour, only: :signup,
             with: -> { render_too_many_requests }
  rate_limit to: 10, within: 1.hour, only: :invitation,
             with: -> { render_too_many_requests }

  # Pre-computed bcrypt digest of an unguessable string. Used as a stand-in
  # password_digest when the email doesn't match a real user, so authenticate
  # still spends bcrypt time and timing can't distinguish the two paths.
  DUMMY_DIGEST = BCrypt::Password.create(SecureRandom.hex(32)).to_s.freeze

  def create
    user = User.find_by(email: params[:email].to_s.downcase) ||
           User.new(password_digest: DUMMY_DIGEST)
    if user.authenticate(params[:password]) && user.persisted?
      @key = ApiKey.create_random(user)
    else
      render json: { error: 401, message: "Incorrect username or password" }, status: :unauthorized
    end
  end

  def signup
    token = InvitationToken.find_by(token: params[:token])
    if token.nil? || token.expires <= Time.current
      render json: { error: 401, message: "Invalid or expired token" }, status: :unauthorized
      return
    end

    user = token.user
    user.name = params[:name]
    user.email = params[:email].to_s.downcase
    user.password = params[:password]
    user.confirmed = true
    if user.save
      token.delete
      @key = ApiKey.create_random(user)
      render :create
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def invitation
    placeholder = User.new(confirmed: false)
    placeholder.save(validate: false)
    @token = InvitationToken.create!(
      token: SecureRandom.hex(16),
      expires: 15.minutes.from_now,
      user: placeholder
    )
  end

  def logout
    digest = ApiKey.digest(request.headers["X-Api-Key"])
    ApiKey.where(key_digest: digest).destroy_all
    head :no_content
  end

  private

  def render_too_many_requests
    render json: { error: 429, message: "Too many attempts. Try again later." }, status: :too_many_requests
  end
end
