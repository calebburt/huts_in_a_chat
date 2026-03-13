require "test_helper"

class ChatTest < ActiveSupport::TestCase
  def setup
    @chat = chats(:one)
  end

  test "should be valid" do
    assert @chat.valid?
  end

  test "name should be present" do
    @chat.name = ""
    assert_not @chat.valid?
  end

  test "should have many messages" do
    assert_respond_to @chat, :messages
  end

  test "should have and belong to many users" do
    assert_respond_to @chat, :users
  end

  test "should destroy messages when destroyed" do
    message = @chat.messages.create!(content: "test", user: users(:one))
    @chat.destroy
    assert_not Message.exists?(message.id)
  end
end
