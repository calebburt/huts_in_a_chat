class CreateJoinTableUserMessage < ActiveRecord::Migration[8.0]
  def change
    create_join_table :users, :chats
  end
end
