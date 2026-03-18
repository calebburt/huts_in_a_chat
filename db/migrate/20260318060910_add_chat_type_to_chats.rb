class AddChatTypeToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :chat_type, :string
  end
end
