json.extract! message, :id, :content, :user_id, :chat_id, :created_at, :updated_at
json.attachment_url(rails_blob_url(message.attachment)) if message.attachment.attached?
json.reactions message.reactions do |reaction|
  json.extract! reaction, :id, :emoji, :user_id, :message_id
end
