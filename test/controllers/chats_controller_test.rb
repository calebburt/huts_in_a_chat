require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @chat = chats(:one)
    @chat.users << @user unless @chat.users.include?(@user)
  end

  test "should get index" do
    get chats_url
    assert_response :success
  end

  test "should get new" do
    get new_chat_url
    assert_response :success
  end

  test "should create chat" do
    assert_difference("Chat.count") do
      post chats_url, params: { chat: { name: "New Chat", user_ids: [ @user.id ] } }
    end

    assert_redirected_to chat_url(Chat.last)
  end

  test "should show chat" do
    get chat_url(@chat)
    assert_response :success
  end

  test "should get edit" do
    get edit_chat_url(@chat)
    assert_response :success
  end

  test "should update chat" do
    patch chat_url(@chat), params: { chat: { name: @chat.name, user_ids: @chat.user_ids } }
    assert_redirected_to chat_url(@chat)
  end

  test "should destroy chat" do
    assert_difference("Chat.count", -1) do
      delete chat_url(@chat)
    end

    assert_redirected_to chats_url
  end

  test "index_dm returns user list via JSON API" do
    api_key = ApiKey.create_random(@user).plaintext_key
    get dm_chats_url(format: :json), headers: { "X-Api-Key" => api_key }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Array)
    refute body.any? { |u| u["id"] == @user.id }, "DM partner list must exclude self"
  end

  test "dm finds-or-creates a DM and returns chat JSON" do
    api_key = ApiKey.create_random(@user).plaintext_key
    target = users(:two)
    assert_difference("Chat.count", 1) do
      get dm_chat_url(target, format: :json), headers: { "X-Api-Key" => api_key }
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "dm", body["chat_type"]

    # Idempotent: second call returns the same chat without creating a new one.
    assert_no_difference("Chat.count") do
      get dm_chat_url(target, format: :json), headers: { "X-Api-Key" => api_key }
    end
    assert_equal body["id"], JSON.parse(response.body)["id"]
  end

  test "dm rejects targeting self with 422" do
    api_key = ApiKey.create_random(@user).plaintext_key
    get dm_chat_url(@user, format: :json), headers: { "X-Api-Key" => api_key }
    assert_response :unprocessable_entity
  end
end
