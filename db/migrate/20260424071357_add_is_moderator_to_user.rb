class AddIsModeratorToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :is_moderator, :boolean
  end
end
