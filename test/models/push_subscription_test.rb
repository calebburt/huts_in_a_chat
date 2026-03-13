require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  def setup
    @subscription = push_subscriptions(:one)
  end

  test "should be valid" do
    assert @subscription.valid?
  end

  test "endpoint should be present" do
    @subscription.endpoint = ""
    assert_not @subscription.valid?
  end

  test "p256dh_key should be present" do
    @subscription.p256dh_key = ""
    assert_not @subscription.valid?
  end

  test "auth_key should be present" do
    @subscription.auth_key = ""
    assert_not @subscription.valid?
  end

  test "should belong to user" do
    assert_respond_to @subscription, :user
  end
end
