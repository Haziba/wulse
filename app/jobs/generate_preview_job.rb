class GeneratePreviewJob < ApplicationJob
  queue_as :default

  def perform(record_klass, record_id, expected_blob_key)
    record = record_klass.constantize.find_by(id: record_id)
    return unless record&.respond_to?(:file) && record.file.attached?

    return unless record.file.blob.key == expected_blob_key

    Preview::Generate.call(record)

    record.reload
    broadcast_document_update(record)
  rescue => e
    Rails.logger.error "Job failed for #{record_klass}(#{record_id}): #{e.class}: #{e.message}"
    raise
  end

  private

  def broadcast_document_update(document)
    Turbo::StreamsChannel.broadcast_replace_to(
      "institution_#{document.institution_id}",
      target: "document_#{document.id}",
      partial: "dashboard/documents/document_row",
      locals: { document: document }
    )
  end
end
