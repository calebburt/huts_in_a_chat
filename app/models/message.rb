class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user

  validates :content, presence: true

  has_one :message_blob, dependent: :destroy

  after_create_commit -> { broadcast_append_to chat }
end
