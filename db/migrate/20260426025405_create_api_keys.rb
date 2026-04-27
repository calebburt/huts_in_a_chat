class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.string :key_digest, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :expiry

      t.timestamps
    end
    add_index :api_keys, :key_digest, unique: true
  end
end
