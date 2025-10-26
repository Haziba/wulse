module Library
  class FilterCounts
    FILTER_KEYS = %w[document_type department language].freeze

    def self.for(scope)
      new(scope).call
    end

    def initialize(scope)
      @scope = scope
    end

    def call
      simple_counts = Metadatum
        .joins(:oer)
        .where(key: FILTER_KEYS)
        .group(:key, :value)
        .count

      facets = FILTER_KEYS.index_with do |key|
        pairs = simple_counts
          .select { |(k, _), _| k == key }
          .map    { |((_, v), c)| [v, c] }
        sort_desc(pairs.to_h)
      end

      facets.merge(publishing_date: tally_years)
    end

    private

    attr_reader :scope

    def tally_years
      adapter = ActiveRecord::Base.connection.adapter_name.downcase

      rel = Metadatum
        .joins(:oer)
        .merge(scope)
        .where(key: "publishing_date")
        .where.not(value: [nil, ""])

      year_expr =
        case adapter
        when /postgres/
          rel = rel.where("metadata.value ~ '^(\\d{4})(-\\d{2}(-\\d{2})?)?$'")
          "to_char((metadata.value)::date, 'YYYY')"
        when /mysql/
          "YEAR(CAST(metadata.value AS date))"
        else
          "strftime('%Y', date(metadata.value))"
        end

      counts = rel.group(Arel.sql(year_expr)).count
      sort_desc(counts)
    end

    def sort_desc(hash)
      hash.sort_by { |_, count| -count }
    end
  end
end
