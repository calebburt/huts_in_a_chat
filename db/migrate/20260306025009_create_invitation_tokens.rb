class CreateInvitationTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :invitation_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :expires
      t.string :token

      t.timestamps
    end
  end
end
