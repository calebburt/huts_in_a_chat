class MessagesChannel < ApplicationCable::Channel
  def subscribed
    chat = Chat.find_by(id: params[:chat_id])
    return reject unless chat && authorized?(chat)

    stream_for chat
  end

  def self.broadcast_message(message, action)
    payload = {
      action: action,
      message: {
        id: message.id,
        content: message.content,
        user_id: message.user_id,
        chat_id: message.chat_id,
        created_at: message.created_at,
        updated_at: message.updated_at,
        attachment_url: message.attachment.attached? ?
          Rails.application.routes.url_helpers.rails_blob_path(message.attachment, host: "https://chat.caleb.burt.id.au") : nil,
        reactions: message.reactions.map { |r|
          { id: r.id, emoji: r.emoji, user_id: r.user_id, message_id: r.message_id }
        }
      }
    }
    broadcast_to(message.chat, payload)
  end

  private

  def authorized?(chat)
    chat.users.exists?(id: current_user.id) || current_user.is_moderator?
  end
end
