json.extract! chat, :id, :name, :chat_type, :created_at, :updated_at
json.url chat_url(chat, format: :json)
json.messages chat.messages, partial: "messages/message", as: :message
