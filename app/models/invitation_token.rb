class InvitationToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true
  validates :expires, presence: true

  validate :expires_in_future

  private

  def expires_in_future
    if expires.present? && expires <= Time.current
      errors.add(:expires, "must be in the future")
    end
  end
end
