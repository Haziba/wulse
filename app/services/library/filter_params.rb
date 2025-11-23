require "zlib"
require "base64"

module Library
  class FilterParams
    FILTERABLE_KEYS = FilterCounts::FILTER_KEYS

    class << self
      def encode(params)
        filter_hash = params.slice(*FILTERABLE_KEYS).to_h do |key, values|
          [key, Array(values)]
        end.compact_blank

        return nil if filter_hash.empty?

        json = filter_hash.to_json
        zstream = Zlib::Deflate.new(Zlib::BEST_COMPRESSION)
        compressed = zstream.deflate(json, Zlib::FINISH)
        zstream.close
        Base64.urlsafe_encode64(compressed, padding: false)
      end

      def decode(encoded_string)
        return {} if encoded_string.blank?

        compressed = Base64.urlsafe_decode64(encoded_string)
        json = Zlib::Inflate.inflate(compressed)
        parsed = JSON.parse(json)

        parsed.slice(*FILTERABLE_KEYS).transform_keys(&:to_s)
      rescue ArgumentError, Zlib::Error, JSON::ParserError
        {}
      end
    end
  end
end
