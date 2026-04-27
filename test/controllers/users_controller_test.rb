require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    sign_in_as users(:one)
    get user_url(users(:one))
    assert_response :success
  end

  test "should get edit" do
    sign_in_as users(:one)
    get edit_user_url(users(:one))
    assert_response :success
  end

  test "show returns user JSON via API key" do
    api_key = ApiKey.create_random(users(:one)).plaintext_key
    get user_url(users(:two), format: :json), headers: { "X-Api-Key" => api_key }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal users(:two).id, body["id"]
    assert_equal users(:two).name, body["name"]
    refute body.key?("email"), "user JSON should not expose email"
    refute body.key?("password_digest"), "user JSON should not expose password_digest"
  end

  test "index returns user list via API key" do
    api_key = ApiKey.create_random(users(:one)).plaintext_key
    get users_url(format: :json), headers: { "X-Api-Key" => api_key }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Array)
    assert body.any? { |u| u["id"] == users(:one).id }
  end
end
