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

  test "should create message via JSON API" do
    api_key = ApiKey.create_random(@user).plaintext_key
    assert_difference("Message.count") do
      post chat_messages_url(@chat, format: :json),
        params: { message: { content: "Hello from API" } },
        headers: { "X-Api-Key" => api_key }
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Hello from API", body["content"]
    assert_equal @user.id, body["user_id"]
    assert_equal @chat.id, body["chat_id"]
  end

  test "JSON create returns 422 for validation failures" do
    api_key = ApiKey.create_random(@user).plaintext_key
    post chat_messages_url(@chat, format: :json),
      params: { message: { content: "" } },
      headers: { "X-Api-Key" => api_key }
    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].any?
  end

  test "JSON update edits the message and returns it" do
    api_key = ApiKey.create_random(@user).plaintext_key
    message = @chat.messages.create!(user: @user, content: "before")

    patch chat_message_url(@chat, message, format: :json),
      params: { message: { content: "after" } },
      headers: { "X-Api-Key" => api_key }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "after", body["content"]
    assert_equal "after", message.reload.content
  end

  test "JSON update returns 422 on validation failure" do
    api_key = ApiKey.create_random(@user).plaintext_key
    message = @chat.messages.create!(user: @user, content: "before")

    patch chat_message_url(@chat, message, format: :json),
      params: { message: { content: "x" * 501 } },
      headers: { "X-Api-Key" => api_key }
    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].any?
    assert_equal "before", message.reload.content
  end

  test "JSON update is forbidden for non-owner non-moderator" do
    other = users(:two)
    @chat.users << other unless @chat.users.include?(other)
    api_key = ApiKey.create_random(other).plaintext_key
    message = @chat.messages.create!(user: @user, content: "mine")

    patch chat_message_url(@chat, message, format: :json),
      params: { message: { content: "hijacked" } },
      headers: { "X-Api-Key" => api_key }
    assert_response :forbidden
    assert_equal "mine", message.reload.content
  end

  test "JSON destroy removes the message and returns 204" do
    api_key = ApiKey.create_random(@user).plaintext_key
    message = @chat.messages.create!(user: @user, content: "delete me")

    assert_difference("Message.count", -1) do
      delete chat_message_url(@chat, message, format: :json),
        headers: { "X-Api-Key" => api_key }
    end
    assert_response :no_content
  end

  test "JSON-body POST without .json URL still gets JSON back" do
    api_key = ApiKey.create_random(@user).plaintext_key
    # Mimics a Python `requests` client: Content-Type is JSON, but the URL has
    # no .json extension and Accept defaults to */*. With turbo_stream listed
    # first in respond_to, the wildcard Accept previously matched turbo_stream.
    post chat_messages_url(@chat),
      params: { message: { content: "hi" } }.to_json,
      headers: { "X-Api-Key" => api_key, "Content-Type" => "application/json" }
    assert_response :created
    assert_equal "application/json", response.media_type
  end

  test "JSON create returns 400 when message param is a scalar instead of a hash" do
    api_key = ApiKey.create_random(@user).plaintext_key
    assert_no_difference("Message.count") do
      post chat_messages_url(@chat, format: :json),
        params: { message: "hello" }, as: :json,
        headers: { "X-Api-Key" => api_key }
    end
    assert_response :bad_request
  end

  test "JSON update returns 400 when message param is a scalar" do
    api_key = ApiKey.create_random(@user).plaintext_key
    message = @chat.messages.create!(user: @user, content: "before")

    patch chat_message_url(@chat, message, format: :json),
      params: { message: "after" }, as: :json,
      headers: { "X-Api-Key" => api_key }
    assert_response :bad_request
    assert_equal "before", message.reload.content
  end

  test "JSON destroy is forbidden for non-owner non-moderator" do
    other = users(:two)
    @chat.users << other unless @chat.users.include?(other)
    api_key = ApiKey.create_random(other).plaintext_key
    message = @chat.messages.create!(user: @user, content: "mine")

    assert_no_difference("Message.count") do
      delete chat_message_url(@chat, message, format: :json),
        headers: { "X-Api-Key" => api_key }
    end
    assert_response :forbidden
  end
end
