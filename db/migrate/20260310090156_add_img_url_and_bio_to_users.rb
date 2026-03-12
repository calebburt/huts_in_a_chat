class AddImgUrlAndBioToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bio, :string
    add_column :users, :img_url, :string
  end
end
