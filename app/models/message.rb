class Message < ApplicationRecord
  belongs_to :chat, dependent: :destroy
  belongs_to :user

  validates :content, presence: true
  validates :content, length: {minimum: 1, maximum: 200}

  after_create_commit -> do 
    broadcast_append_to chat
    SendMessagePushJob.perform_later(self)
  end
end
