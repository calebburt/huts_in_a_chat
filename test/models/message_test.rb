require "test_helper"

class MessageTest < ActiveSupport::TestCase
  def setup
    @message = messages(:one)
  end

  test "should be valid" do
    assert @message.valid?
  end

  test "content should be present" do
    @message.content = ""
    assert_not @message.valid?
  end

  test "content should have minimum length" do
    @message.content = ""
    assert_not @message.valid?
  end

  test "content should have maximum length" do
    @message.content = "a" * 201
    assert_not @message.valid?
  end

  test "should belong to chat" do
    assert_respond_to @message, :chat
  end

  test "should belong to user" do
    assert_respond_to @message, :user
  end

  test "should enqueue push job after create" do
    assert_enqueued_with(job: SendMessagePushJob) do
      Message.create!(content: "test", chat: chats(:one), user: users(:one))
    end
  end
end
