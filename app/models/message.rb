class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user

  validates :content, presence: true, if: -> { !attachment.attached? }
  validates :content, length: { maximum: 200 }

  has_one_attached :attachment

  after_create_commit do
    broadcast_to_recipients(:append) unless Rails.env.test?
    SendMessagePushJob.perform_later(self)
  end

  after_update_commit do
    broadcast_to_recipients(:replace) unless Rails.env.test?
  end

  after_destroy_commit do
    broadcast_to_recipients(:remove) unless Rails.env.test?
  end

  # The set of users who can be viewing this message and therefore need
  # to receive the broadcast: chat members plus any moderators.
  def broadcast_recipients
    member_ids = chat.user_ids
    chat.users + User.where(is_moderator: true).where.not(id: member_ids)
  end

  private

  # Broadcasts the message once per recipient, with Current.user set to that
  # recipient so the rendered partial reflects their perspective (e.g. "You"
  # alignment vs. someone else's name). The previous single global broadcast
  # rendered with the sender's perspective, so all recipients saw the message
  # styled as their own.
  def broadcast_to_recipients(action)
    broadcast_recipients.each do |recipient|
      stream = [ chat, recipient ]
      case action
      when :append
        Current.set(user: recipient) { broadcast_append_to(stream) }
      when :replace
        Current.set(user: recipient) { broadcast_replace_to(stream) }
      when :remove
        broadcast_remove_to(stream)
      end
    end
  end
end
