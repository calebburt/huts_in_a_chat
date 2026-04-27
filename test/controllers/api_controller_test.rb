require "test_helper"

class ApiControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  def api_login(user = @user, password: "password")
    post api_create_url, params: { email: user.email, password: password }
    JSON.parse(response.body).fetch("key")
  end

  # --- create (login) -------------------------------------------------------

  test "create returns a key with valid credentials" do
    post api_create_url, params: { email: @user.email, password: "password" }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["key"].present?
    assert_equal @user.id, body["user_id"]
    assert_equal @user, ApiKey.authenticate(body["key"])
  end

  test "create accepts mixed-case emails" do
    post api_create_url, params: { email: @user.email.upcase, password: "password" }
    assert_response :success
  end

  test "create returns 401 with wrong password" do
    post api_create_url, params: { email: @user.email, password: "not-the-password" }
    assert_response :unauthorized
  end

  test "create returns 401 for unknown email" do
    post api_create_url, params: { email: "nobody@example.com", password: "password" }
    assert_response :unauthorized
  end

  test "create returns 401 with missing params" do
    post api_create_url, params: {}
    assert_response :unauthorized
  end

  test "issued key authenticates against protected endpoints" do
    key = api_login
    get chats_url(format: :json), headers: { "X-Api-Key" => key, "Accept" => "application/json" }
    assert_response :success
  end

  # --- invitation ----------------------------------------------------------

  test "invitation returns a token for an authenticated caller" do
    key = api_login
    assert_difference -> { InvitationToken.count } => 1, -> { User.count } => 1 do
      post api_invitation_url, headers: { "X-Api-Key" => key }
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert body["expires"].present?
  end

  test "invitation requires authentication" do
    post api_invitation_url
    assert_response :forbidden
  end

  # --- signup --------------------------------------------------------------

  test "signup completes the invitation and returns a key" do
    key = api_login
    post api_invitation_url, headers: { "X-Api-Key" => key }
    token = JSON.parse(response.body).fetch("token")

    post api_signup_url, params: {
      token: token, name: "Charlie", email: "charlie@example.com", password: "password123"
    }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["key"].present?

    user = ApiKey.authenticate(body["key"])
    assert_equal "charlie@example.com", user.email
    assert user.confirmed?
    assert_nil InvitationToken.find_by(token: token)
  end

  test "signup rejects an unknown token" do
    post api_signup_url, params: {
      token: "not-a-token", name: "X", email: "x@example.com", password: "password123"
    }
    assert_response :unauthorized
  end

  test "signup rejects an expired token" do
    placeholder = User.new(confirmed: false)
    placeholder.save(validate: false)
    expired = InvitationToken.new(token: SecureRandom.hex(8), user: placeholder, expires: 1.minute.ago)
    expired.save(validate: false)

    post api_signup_url, params: {
      token: expired.token, name: "X", email: "x@example.com", password: "password123"
    }
    assert_response :unauthorized
  end

  test "signup rejects validation failures (e.g. short password)" do
    key = api_login
    post api_invitation_url, headers: { "X-Api-Key" => key }
    token = JSON.parse(response.body).fetch("token")

    post api_signup_url, params: {
      token: token, name: "Charlie", email: "charlie@example.com", password: "short"
    }
    assert_response :unprocessable_entity
  end

  # --- logout --------------------------------------------------------------

  test "logout revokes the current api key" do
    key = api_login
    assert_difference -> { ApiKey.count } => -1 do
      delete api_logout_url, headers: { "X-Api-Key" => key }
    end
    assert_response :no_content

    get chats_url(format: :json), headers: { "X-Api-Key" => key, "Accept" => "application/json" }
    assert_response :forbidden
  end

  test "logout requires authentication" do
    delete api_logout_url
    assert_response :forbidden
  end
end
