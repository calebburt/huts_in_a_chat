class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user

  validates :content, presence: true

  has_one :message_blob, dependent: :destroy
end
