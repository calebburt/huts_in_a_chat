class Chat < ApplicationRecord
  has_many :messages
  has_and_belongs_to_many :users

  enum :chat_type, { group_chat: "group", dm: "dm" }

  validates :name, presence: true

  scope :between, ->(u1, u2) {
    where(chat_type: :dm)
      .joins(:users)
      .where(users: { id: [u1.id, u2.id] })
      .group("chats.id")
      .having("COUNT(users.id) = 2")
  }

  def self.find_or_create_dm(user1, user2)
    # Return existing DM if it exists
    existing = Chat.between(user1, user2).first
    return existing if existing

    # Otherwise create a new one
    Chat.create!(chat_type: :dm, users: [user1, user2], name: "#{user1.name} & #{user2.name}")
  end
end
