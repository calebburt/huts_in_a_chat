class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :message

  validates :emoji, presence: true, length: { maximum: 32 },
                    uniqueness: { scope: [ :user_id, :message_id ] }

  after_commit :rebroadcast_message, on: [ :create, :destroy ]

  private

  # Re-render the parent message for every recipient so reaction chips appear
  # / disappear live. Skipped if the message itself was just destroyed (the
  # message's own :remove broadcast already covers that case).
  def rebroadcast_message
    return if Rails.env.test?
    return unless Message.exists?(id: message_id)
    fresh = message.reload
    fresh.send(:broadcast_to_recipients, :replace)
    MessagesChannel.broadcast_message(fresh, :replace)
  end
end
