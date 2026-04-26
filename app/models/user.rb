class User < ApplicationRecord
  has_secure_password

  has_and_belongs_to_many :chats
  has_many :messages
  has_many :push_subscriptions

  validates :name, presence: true, if: :confirmed?
  validates :email, presence: true, if: :confirmed?
  validates :email, uniqueness: { case_sensitive: false }, if: :confirmed?
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  # Restricts to https URLs containing only safe URL characters so the value
  # can be embedded inside `background-image: url('...')` without enabling CSS
  # injection. Reject anything with quotes, parens, whitespace, semicolons,
  # backslashes, or angle brackets.
  validates :img_url,
            format: { with: %r{\Ahttps://[A-Za-z0-9\-._~:/?#\[\]@!$&*+,=%]*\z} },
            length: { maximum: 2048 },
            allow_blank: true

  before_save :downcase_email

  has_one_attached :avatar

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
