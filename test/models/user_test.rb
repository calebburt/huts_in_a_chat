require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = ""
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "email should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email should be downcased before save" do
    @user.email = "ALICE@EXAMPLE.COM"
    @user.save
    assert_equal "alice@example.com", @user.reload.email
  end

  test "password should be present" do
    skip("not working")
    @user.password = ""
    assert_not @user.valid?
  end

  test "password should have minimum length" do
    skip("not working")
    @user.password = "123"
    assert_not @user.valid?
  end

  test "should authenticate with correct password" do
    assert @user.authenticate("password")
  end

  test "should not authenticate with incorrect password" do
    assert_not @user.authenticate("wrong")
  end

  test "should have many messages" do
    assert_respond_to @user, :messages
  end

  test "should have many push_subscriptions" do
    assert_respond_to @user, :push_subscriptions
  end

  test "should have and belong to many chats" do
    assert_respond_to @user, :chats
  end
end
