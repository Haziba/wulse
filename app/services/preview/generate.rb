require "mini_magick"
require "open3"

module Preview
  class Generate
    def self.call(record, attachment_name: :file, preview_name: :preview_image)
      new(record, attachment_name, preview_name).call
    end

    def initialize(record, attachment_name, preview_name)
      @record         = record
      @attachment     = record.public_send(attachment_name)
      @preview_attach = record.public_send(preview_name)
      @blob           = @attachment.blob
    end

    def call
      case @blob.content_type
      when "application/pdf"
        attach_pdf_preview
      when "application/epub+zip"
        attach_epub_cover
      else
        # No-op for unsupported types; you can attach a branded fallback if you want.
        Rails.logger.info "[Preview] Unsupported content-type: #{@blob.content_type}"
      end
    end

    private

    def attach_pdf_preview
      # Prefer Active Storage previewer if available (Poppler/MuPDF installed)
      if @attachment.variable? || @blob.previewable?
        variant = @attachment.preview(resize_to_limit: [ 600, 800 ]).processed
        io      = StringIO.new(variant.image.download)
        @preview_attach.attach(
          io: io,
          filename: preview_filename("pdf", "jpg"),
          content_type: "image/jpeg"
        )
        return
      end

      # Fallback using pdftoppm (Poppler). Safer and faster than Ghostscript via ImageMagick.
      Tempfile.create([ "pdfthumb", ".jpg" ]) do |outfile|
        @attachment.open do |file|
          cmd = [
            "pdftoppm", "-jpeg", "-singlefile", "-f", "1", "-l", "1",
            "-scale-to", "1000", file.path, outfile.path.sub(/\.jpg\z/, "")
          ]
          run_cmd!(cmd)
        end

        # Resize + compress with MiniMagick to target dimensions
        image = MiniMagick::Image.open(outfile.path)
        image.resize "600x800>"
        image.strip
        image.quality "85"

        @preview_attach.attach(
          io: File.open(image.path),
          filename: preview_filename("pdf", "jpg"),
          content_type: "image/jpeg"
        )
      end
    end

    def attach_epub_cover
      bytes, mime = EpubCover.extract(@attachment)
      return unless bytes

      @preview_attach.attach(
        io: StringIO.new(bytes),
        filename: preview_filename("epub", extension_for(mime)),
        content_type: mime
      )
    end

    def preview_filename(kind, ext)
      base = @blob.filename.base.parameterize.presence || kind
      "#{base}-preview.#{ext}"
    end

    def extension_for(mime)
      case mime
      when "image/png"  then "png"
      when "image/webp" then "webp"
      else "jpg"
      end
    end

    def run_cmd!(argv, timeout: 20)
      stdout, stderr, status = Open3.capture3(*argv)
      raise "Command failed: #{argv.join(' ')} -- #{stderr}" unless status.success?
      stdout
    end
  end
end
