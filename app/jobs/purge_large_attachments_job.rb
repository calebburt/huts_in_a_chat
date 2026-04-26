class PurgeLargeAttachmentsJob < ApplicationJob
  queue_as :default

  def perform
    ActiveStorage::Attachment
      .where(record_type: "Message", name: "attachment")
      .joins(:blob)
      .where("active_storage_blobs.byte_size > ?", Message::LARGE_ATTACHMENT_BYTES)
      .where("active_storage_blobs.created_at < ?", Message::LARGE_ATTACHMENT_TTL.ago)
      .find_each(&:purge_later)
  end
end
