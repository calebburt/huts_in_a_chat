require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @chat = chats(:one)
    @chat.users << @user unless @chat.users.include?(@user)
  end

  test "index returns older messages as turbo_stream and updates sentinel" do
    chat = Chat.create!(chat_type: :group_chat, name: "Pagi", users: [ @user ])
    total = Message::PAGE_SIZE + 5
    created = total.times.map { |i| chat.messages.create!(user: @user, content: "msg #{i}") }
    cursor = created.last.id

    get chat_messages_url(chat, before_id: cursor),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type

    # Older messages get inserted after the sentinel; the next-oldest message
    # (the one just before our cursor) should appear in the response.
    assert_match(/turbo-stream action="after" target="messages_top_sentinel"/, response.body)
    assert_match(/msg #{total - 2}/, response.body)
    # More than one page of older messages remain, so the sentinel should be
    # replaced rather than removed.
    assert_match(/turbo-stream action="replace" target="messages_top_sentinel"/, response.body)
  end

  test "index removes the sentinel when no more messages remain" do
    chat = Chat.create!(chat_type: :group_chat, name: "Short", users: [ @user ])
    created = Message::PAGE_SIZE.times.map { |i| chat.messages.create!(user: @user, content: "msg #{i}") }
    cursor = created.last.id

    get chat_messages_url(chat, before_id: cursor),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/turbo-stream action="remove" target="messages_top_sentinel"/, response.body)
  end

  test "index rejects missing or invalid before_id" do
    get chat_messages_url(@chat),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :bad_request
  end

  test "index forbids non-members who aren't moderators" do
    other = users(:two)
    sign_in_as other
    get chat_messages_url(@chat, before_id: 999_999),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    # deny_access redirects on html/turbo_stream; just check it didn't 200.
    assert_not_equal 200, response.status
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
    # no .json extension and Accept is */*. With format.json listed first in
    # respond_to, the wildcard Accept matches it.
    post chat_messages_url(@chat),
      params: { message: { content: "hi" } }.to_json,
      headers: {
        "X-Api-Key" => api_key,
        "Content-Type" => "application/json",
        "Accept" => "*/*"
      }
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
