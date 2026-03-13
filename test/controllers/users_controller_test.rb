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
end
