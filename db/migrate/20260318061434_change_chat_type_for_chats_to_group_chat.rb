class ChangeChatTypeForChatsToGroupChat < ActiveRecord::Migration[8.1]
  def up
    Chat.update_all(chat_type: "group")
  end

  def down
    Chat.update_all(chat_type: nil)
  end
end
