class GeneratePreviewJob < ApplicationJob
  queue_as :default

  def perform(record_klass, record_id, expected_blob_key)
    record = record_klass.constantize.find_by(id: record_id)
    return unless record&.respond_to?(:document) && record.document.attached?

    return unless record.document.blob.key == expected_blob_key

    Preview::Generate.call(record)
  rescue => e
    Rails.logger.error "Job failed for #{record_klass}(#{record_id}): #{e.class}: #{e.message}"
    raise
  end
end
