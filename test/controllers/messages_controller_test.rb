require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @chat = chats(:one)
    @chat.users << @user unless @chat.users.include?(@user)
  end

  test "should create message" do
    assert_difference("Message.count") do
      post chat_messages_url(@chat), params: { message: { content: "Hello world" } }
    end
  end
end
