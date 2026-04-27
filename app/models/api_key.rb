class ApiKey < ApplicationRecord
  belongs_to :user

  scope :active, -> { where("expiry IS NULL OR expiry > ?", Time.current) }

  attr_reader :plaintext_key

  def self.create_random(user)
    plaintext = SecureRandom.urlsafe_base64(32)
    record = create!(key_digest: digest(plaintext), user: user)
    record.instance_variable_set(:@plaintext_key, plaintext)
    record
  end

  def self.authenticate(plaintext)
    return nil if plaintext.blank?
    active.find_by(key_digest: digest(plaintext))&.user
  end

  # HMAC with secret_key_base — deterministic so we can index-lookup, but a
  # raw DB dump alone is not enough to mint or use a valid key.
  def self.digest(plaintext)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, plaintext.to_s)
  end
end
