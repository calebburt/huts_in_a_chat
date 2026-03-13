require "test_helper"

class InvitationTokenTest < ActiveSupport::TestCase
  def setup
    @token = invitation_tokens(:one)
  end

  test "should be valid" do
    assert @token.valid?
  end

  test "token should be present" do
    @token.token = ""
    assert_not @token.valid?
  end

  test "expires should be present" do
    @token.expires = nil
    assert_not @token.valid?
  end

  test "should belong to user" do
    assert_respond_to @token, :user
  end

  test "should be invalid if expired" do
    @token.expires = 1.day.ago
    assert_not @token.valid?
  end

  test "should be valid if not expired" do
    @token.expires = 1.day.from_now
    assert @token.valid?
  end
end
