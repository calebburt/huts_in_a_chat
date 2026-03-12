class SendMessagePushJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(message)
    logger.error("sending push notification for message #{message.inspect}")
    title = "New message in #{message.chat.name}"

    message_json = {
      title: title,
      body: message.content,
      icon: "/icon.png"
    }.to_json

    message.chat.users.each do |user|
      user.push_subscriptions.each do |subscription|
        endpoint = subscription.endpoint
        p256dh_key = subscription.p256dh_key
        auth_key = subscription.auth_key
        response = WebPush.payload_send(
          message: message_json,
          endpoint: endpoint,
          p256dh: p256dh_key,
          auth: auth_key,
          vapid: {
            public_key: Rails.application.credentials.vapid.public,
            private_key: Rails.application.credentials.vapid.private
          }
        )
      end
    end
  end
end
