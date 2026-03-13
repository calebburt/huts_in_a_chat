require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "should get login page" do
    get auth_login_url
    assert_response :success
  end

  test "should get accept with valid token" do
    token = InvitationToken.create!(token: SecureRandom.hex(10), expires: 15.minutes.from_now, user: users(:one))
    get auth_accept_url(token: token.token)
    assert_response :success
  end

  test "should create invitation when logged in" do
    sign_in_as users(:one)
    post auth_create_url
    assert_response :redirect
  end
end
