class SendMessagePushJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(message)
    payload = {
      title: "New message in #{message.chat.name}",
      options: {
        body: notification_body(message),
        icon: "/icon.png"
      }
    }.to_json

    # Don't notify the sender on their own message.
    message.chat.users.where.not(id: message.user_id).find_each do |user|
      user.push_subscriptions.find_each do |subscription|
        send_push(payload, subscription)
      end
    end
  end

  private

  def notification_body(message)
    if message.content.present?
      message.content
    elsif message.attachment.attached?
      "[attachment]"
    else
      ""
    end
  end

  def send_push(payload, subscription)
    WebPush.payload_send(
      message: payload,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      vapid: {
        public_key: Rails.application.credentials.vapid.public,
        private_key: Rails.application.credentials.vapid.private
      }
    )
  rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription, WebPush::Unauthorized
    # Endpoint is dead — drop it so we don't keep trying.
    subscription.destroy
  rescue WebPush::ResponseError => e
    Rails.logger.error("Push send failed for subscription #{subscription.id}: #{e.message}")
  end
end
