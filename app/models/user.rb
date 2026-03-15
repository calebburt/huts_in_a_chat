class User < ApplicationRecord
  has_secure_password

  has_and_belongs_to_many :chats
  has_many :messages
  has_many :push_subscriptions

  validates :name, presence: true, if: :confirmed?
  validates :email, presence: true, if: :confirmed?
  validates :email, uniqueness: { case_sensitive: false }, if: :confirmed?

  before_save :downcase_email

  has_one_attached :avatar

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
