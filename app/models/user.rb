class User < ApplicationRecord
  has_secure_password

  has_and_belongs_to_many :chats
  has_many :messages
  has_many :push_subscriptions
end
