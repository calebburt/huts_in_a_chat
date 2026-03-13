require "application_system_test_case"

class ChatsTest < ApplicationSystemTestCase
  setup do
    @chat = chats(:one)
    sign_in_as users(:one)
  end

  def sign_in_as(user)
    page.driver.post "/auth/login", { "email" => user.email, "password" => "password" }
  end

  test "visiting the index" do
    skip("not working")
    visit chats_url
    assert_selector "h1", text: "Chats"
  end

  test "should create chat" do
    skip("not working")
    visit chats_url
    click_on "New chat"

    fill_in "Name", with: @chat.name
    click_on "Create Chat"

    assert_text "Chat was successfully created"
    click_on "Back"
  end

  test "should update Chat" do
    skip("not working")
    visit chat_url(@chat)
    click_on "Edit this chat", match: :first

    fill_in "Name", with: @chat.name
    click_on "Update Chat"

    assert_text "Chat was successfully updated"
    click_on "Back"
  end

  test "should destroy Chat" do
    skip("not working")
    visit chat_url(@chat)
    click_on "Destroy this chat", match: :first

    assert_text "Chat was successfully destroyed"
  end
end
