require 'rails_helper'

RSpec.describe Preview::EpubCover do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:oer) { create(:oer, institution: institution, staff: staff) }

  describe ".extract" do
    context "with test_book.epub that has a cover" do
      before do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_book.epub')),
          filename: 'test_book.epub',
          content_type: 'application/epub+zip'
        )
      end

      it "returns cover image data and mime type" do
        bytes, mime = described_class.extract(oer.file)

        expect(bytes).not_to be_nil
        expect(bytes).to be_a(String)
        expect(bytes.bytesize).to be > 0
        expect(mime).to be_a(String)
        expect(mime).to match(/^image\//)
      end
    end

    context "with test_book_no_cover.epub that has no cover" do
      before do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_book_no_cover.epub')),
          filename: 'test_book_no_cover.epub',
          content_type: 'application/epub+zip'
        )
      end

      it "returns nil for both bytes and mime type" do
        bytes, mime = described_class.extract(oer.file)

        expect(bytes).to be_nil
        expect(mime).to be_nil
      end
    end

    context "error handling" do
      before do
        oer.file.attach(
          io: StringIO.new("not a valid epub"),
          filename: 'invalid.epub',
          content_type: 'application/epub+zip'
        )
      end

      it "logs a warning and returns nil on error" do
        allow(Rails.logger).to receive(:warn)

        bytes, mime = described_class.extract(oer.file)

        expect(bytes).to be_nil
        expect(mime).to be_nil
        expect(Rails.logger).to have_received(:warn).with(/cover extraction failed/)
      end
    end
  end
end
