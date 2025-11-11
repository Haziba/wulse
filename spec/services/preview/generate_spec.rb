require 'rails_helper'

RSpec.describe Preview::Generate do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:oer) { create(:oer, institution: institution, staff: staff) }

  describe ".call" do
    context "PDF generation" do
      before do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_document.pdf')),
          filename: 'test_document.pdf',
          content_type: 'application/pdf'
        )
      end

      context "when ActiveStorage previewer is available" do
        it "uses ActiveStorage previewer and sizes to 600x800" do
          # Mock that the blob is previewable
          allow(oer.file.blob).to receive(:previewable?).and_return(true)

          # Create a mock variant
          mock_variant = double('variant')
          mock_image = double('image', download: 'fake_image_data')
          allow(mock_variant).to receive(:image).and_return(mock_image)
          allow(mock_variant).to receive(:processed).and_return(mock_variant)

          # Expect preview to be called with correct dimensions
          expect(oer.file).to receive(:preview).with(resize_to_limit: [600, 800]).and_return(mock_variant)

          described_class.call(oer)

          expect(oer.preview_image).to be_attached
        end
      end

      context "when ActiveStorage previewer is not available" do
        before do
          allow(oer.file).to receive(:variable?).and_return(false)
          allow(oer.file.blob).to receive(:previewable?).and_return(false)
        end

        it "uses pdftoppm (Poppler) and sizes to 600x800" do
          # Mock the pdftoppm command
          allow(Open3).to receive(:capture3).and_return(['', '', double(success?: true)])

          # Create a real tempfile for the mock image
          temp_image_file = Tempfile.new(['test_image', '.jpg'])
          temp_image_file.write('fake image data')
          temp_image_file.rewind

          # Mock MiniMagick operations
          mock_image = double('MiniMagick::Image')
          allow(MiniMagick::Image).to receive(:open).and_return(mock_image)
          allow(mock_image).to receive(:resize).with("600x800>")
          allow(mock_image).to receive(:strip)
          allow(mock_image).to receive(:quality).with("85")
          allow(mock_image).to receive(:path).and_return(temp_image_file.path)

          described_class.call(oer)

          expect(oer.preview_image).to be_attached
          expect(MiniMagick::Image).to have_received(:open)
          expect(mock_image).to have_received(:resize).with("600x800>")

          temp_image_file.close
          temp_image_file.unlink
        end

        it "calls pdftoppm with correct arguments" do
          # Create a real tempfile for the mock image
          temp_image_file = Tempfile.new(['test_image', '.jpg'])
          temp_image_file.write('fake image data')
          temp_image_file.rewind

          allow(MiniMagick::Image).to receive(:open).and_return(
            double('image', resize: nil, strip: nil, quality: nil, path: temp_image_file.path)
          )

          expect(Open3).to receive(:capture3) do |*args|
            expect(args[0]).to eq('pdftoppm')
            expect(args).to include('-jpeg', '-singlefile', '-f', '1', '-l', '1', '-scale-to', '1000')
            ['', '', double(success?: true)]
          end

          described_class.call(oer)

          temp_image_file.close
          temp_image_file.unlink
        end
      end
    end

    context "EPUB generation" do
      it "processes EPUB with cover without error" do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_book.epub')),
          filename: 'test_book.epub',
          content_type: 'application/epub+zip'
        )

        # Verify the EPUB has extractable cover data
        bytes, _mime = Preview::EpubCover.extract(oer.file)
        expect(bytes).not_to be_nil

        # Call the service - it should extract and attach without error
        expect {
          described_class.call(oer)
        }.not_to raise_error
      end

      it "does not attach preview when EPUB has no cover" do
        oer.file.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_book_no_cover.epub')),
          filename: 'test_book_no_cover.epub',
          content_type: 'application/epub+zip'
        )

        described_class.call(oer)

        expect(oer.preview_image).not_to be_attached
      end
    end

    context "unsupported file types" do
      it "does nothing for text files" do
        oer.file.attach(
          io: StringIO.new("plain text content"),
          filename: 'document.txt',
          content_type: 'text/plain'
        )

        allow(Rails.logger).to receive(:info)

        described_class.call(oer)

        expect(oer.preview_image).not_to be_attached
        expect(Rails.logger).to have_received(:info).with(/Unsupported content-type: text\/plain/)
      end

      it "does nothing for word documents" do
        oer.file.attach(
          io: StringIO.new("fake docx content"),
          filename: 'document.docx',
          content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        )

        allow(Rails.logger).to receive(:info)

        described_class.call(oer)

        expect(oer.preview_image).not_to be_attached
        expect(Rails.logger).to have_received(:info).with(/Unsupported content-type/)
      end

      it "does nothing for zip files" do
        oer.file.attach(
          io: StringIO.new("fake zip content"),
          filename: 'document.zip',
          content_type: 'application/zip'
        )

        allow(Rails.logger).to receive(:info)

        described_class.call(oer)

        expect(oer.preview_image).not_to be_attached
        expect(Rails.logger).to have_received(:info).with(/Unsupported content-type: application\/zip/)
      end
    end
  end
end
