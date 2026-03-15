class Message < ApplicationRecord
  belongs_to :chat, dependent: :destroy
  belongs_to :user

  validates :content, presence: true
  validates :content, length: { minimum: 1, maximum: 200 }

  has_one_attached :attachment

  after_create_commit -> do
    if !Rails.env.test?
      broadcast_append_to chat
    end
    SendMessagePushJob.perform_later(self)
  end
end
