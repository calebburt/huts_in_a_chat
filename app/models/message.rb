class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user

  validates :content, presence: true, if: -> { !attachment.attached? }
  validates :content, length: { maximum: 200 }

  has_one_attached :attachment

  after_create_commit -> do
    if !Rails.env.test?
      broadcast_append_to chat
    end
    SendMessagePushJob.perform_later(self)
  end
end
