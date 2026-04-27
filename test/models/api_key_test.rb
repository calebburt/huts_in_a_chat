require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "create_random returns a persisted record exposing the plaintext once" do
    key = ApiKey.create_random(@user)
    assert key.persisted?
    assert key.plaintext_key.present?
    refute_equal key.plaintext_key, key.key_digest
  end

  test "plaintext key is not stored in the database" do
    key = ApiKey.create_random(@user)
    assert_nil ApiKey.where("key_digest = ?", key.plaintext_key).first
  end

  test "authenticate finds the user from a valid plaintext key" do
    key = ApiKey.create_random(@user)
    assert_equal @user, ApiKey.authenticate(key.plaintext_key)
  end

  test "authenticate returns nil for an unknown key" do
    assert_nil ApiKey.authenticate("not-a-real-key")
  end

  test "authenticate returns nil for a blank key" do
    assert_nil ApiKey.authenticate("")
    assert_nil ApiKey.authenticate(nil)
  end

  test "authenticate returns nil for an expired key" do
    key = ApiKey.create_random(@user)
    key.update!(expiry: 1.minute.ago)
    assert_nil ApiKey.authenticate(key.plaintext_key)
  end

  test "authenticate accepts keys with no expiry" do
    key = ApiKey.create_random(@user)
    key.update!(expiry: nil)
    assert_equal @user, ApiKey.authenticate(key.plaintext_key)
  end
end
