require "zip"
require "nokogiri"

module Preview
  class EpubCover
    def self.extract(attached_epub)
      new(attached_epub).extract
    end

    def initialize(attached_epub)
      @attached_epub = attached_epub
    end

    def extract
      @attached_epub.open do |file|
        Zip::File.open(file.path) do |zip|
          opf_path = read_container_for_opf(zip)
          return [ nil, nil ] unless opf_path

          opf_xml = read_zip_text(zip, opf_path)
          return [ nil, nil ] unless opf_xml

          opf = Nokogiri::XML(opf_xml)
          cover_item = find_cover_item(opf)
          return [ nil, nil ] unless cover_item

          href = cover_item["href"]
          mime = cover_item["media-type"] || guess_mime(href)

          img_path = normalize_path(File.dirname(opf_path), href)
          entry = zip.find_entry(img_path) || zip.find_entry(href) || best_effort_find(zip, href)
          return [ nil, nil ] unless entry

          bytes = entry.get_input_stream.read
          [ bytes, mime ]
        end
      end
    rescue => e
      Rails.logger.warn "[Preview][EPUB] cover extraction failed: #{e.class}: #{e.message}"
      [ nil, nil ]
    end

    private

    def read_container_for_opf(zip)
      container = read_zip_text(zip, "META-INF/container.xml")
      return nil unless container
      doc = Nokogiri::XML(container)
      doc.at_xpath("//xmlns:rootfile")&.[]("full-path")
    end

    def read_zip_text(zip, path)
      zip.find_entry(path)&.get_input_stream&.read
    end

    def find_cover_item(opf)
      # EPub3: properties="cover-image"
      cover = opf.at_xpath("//xmlns:manifest/xmlns:item[contains(@properties,'cover-image')]")
      return cover if cover

      # Legacy: <meta name="cover" content="cover-id">
      cover_id = opf.at_xpath("//xmlns:metadata/xmlns:meta[@name='cover']/@content")&.value
      return opf.at_xpath("//xmlns:manifest/xmlns:item[@id='#{cover_id}']") if cover_id

      # Fallback: first image in manifest
      opf.at_xpath("//xmlns:manifest/xmlns:item[starts-with(@media-type,'image/')]")
    end

    def normalize_path(base, rel)
      File.expand_path(rel, "#{base}/")
    end

    def best_effort_find(zip, href)
      base = File.basename(href).downcase
      zip.entries.find { |e| !e.directory? && File.basename(e.name).downcase == base }
    end

    def guess_mime(name)
      n = name.to_s.downcase
      return "image/png"  if n.end_with?(".png")
      return "image/webp" if n.end_with?(".webp")
      "image/jpeg"
    end
  end
end
