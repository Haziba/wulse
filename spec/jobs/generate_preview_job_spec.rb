require 'rails_helper'

RSpec.describe GeneratePreviewJob, type: :job do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:oer) { create(:oer, institution: institution, staff: staff) }

  describe "#perform" do
    context "when the record previously had no document" do
      it "calls Preview::Generate" do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_document.pdf')),
          filename: 'test_document.pdf',
          content_type: 'application/pdf'
        )
        blob_key = oer.file.blob.key

        expect(Preview::Generate).to receive(:call).with(oer)

        GeneratePreviewJob.perform_now('Oer', oer.id, blob_key)
      end
    end

    context "when the record had a document" do
      before do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_document.pdf')),
          filename: 'old_document.pdf',
          content_type: 'application/pdf'
        )
      end

      it "calls Preview::Generate with new document" do
        # Attach a new document
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_document.pdf')),
          filename: 'new_document.pdf',
          content_type: 'application/pdf'
        )
        new_blob_key = oer.file.blob.key

        expect(Preview::Generate).to receive(:call).with(oer)

        GeneratePreviewJob.perform_now('Oer', oer.id, new_blob_key)
      end
    end

    context "when the record document is different from expected_blob_key" do
      before do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_document.pdf')),
          filename: 'document.pdf',
          content_type: 'application/pdf'
        )
      end

      it "does not call Preview::Generate" do
        wrong_blob_key = "incorrect_blob_key_12345"

        expect(Preview::Generate).not_to receive(:call)

        GeneratePreviewJob.perform_now('Oer', oer.id, wrong_blob_key)
      end
    end

    context "when the record does not exist" do
      it "does not call Preview::Generate" do
        expect(Preview::Generate).not_to receive(:call)

        GeneratePreviewJob.perform_now('Oer', 99999, 'some_blob_key')
      end
    end

    context "when the record does not have a document attached" do
      it "does not call Preview::Generate" do
        expect(Preview::Generate).not_to receive(:call)

        GeneratePreviewJob.perform_now('Oer', oer.id, 'some_blob_key')
      end
    end

    context "when an error occurs" do
      before do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_document.pdf')),
          filename: 'document.pdf',
          content_type: 'application/pdf'
        )
      end

      it "logs the error and re-raises" do
        blob_key = oer.file.blob.key
        allow(Preview::Generate).to receive(:call).and_raise(StandardError.new("Test error"))
        allow(Rails.logger).to receive(:error)

        expect {
          GeneratePreviewJob.perform_now('Oer', oer.id, blob_key)
        }.to raise_error(StandardError, "Test error")

        expect(Rails.logger).to have_received(:error).with(/Job failed for Oer\(#{oer.id}\): StandardError: Test error/)
      end
    end
  end
end
