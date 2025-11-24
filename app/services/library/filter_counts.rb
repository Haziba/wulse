module Library
  class FilterCounts
    FILTER_KEYS = %w[document_type department language publishing_date].freeze

    def self.for(scope, selected_filters: {})
      new(scope, selected_filters:).call
    end

    def initialize(scope, selected_filters: {})
      @scope = scope
      @selected_filters = selected_filters
    end

    def call
      all_filters = get_filters(Document.all)
      filtered_filters = get_filters(@scope)

      combined_filters = all_filters.map do |key, filter_values|
        filtered_filters_hash = filtered_filters[key].to_h
        inner_filters = filter_values.map do |inner_key, value|
          [ inner_key, filtered_filters_hash[inner_key] || 0 ]
        end
        [ key, sort_filter_values(key, inner_filters) ]
      end
      combined_filters.reject { |_, values| values.size == 1 && values.first.first == "(Unknown)" }
    end

    def sort_filter_values(key, values)
      selected = Array(@selected_filters[key.to_s])
      values.sort_by do |inner_key, count|
        is_checked = selected.empty? || selected.include?(inner_key)
        [ is_checked ? 0 : 1, -count, -inner_key.to_i ]
      end
    end

    private

    def get_filters(scope)
      document_ids = scope.pluck(:id)

      simple_counts = Metadatum
        .where(document_id: document_ids)
        .where(key: FILTER_KEYS)
        .group(:key, :value)
        .count

      facets = FILTER_KEYS.excluding("publishing_date").index_with do |key|
        pairs = simple_counts
          .select { |(k, _), _| k == key }
          .map    { |((_, v), c)| [ v, c ] }

        unknown_count = count_unknown(document_ids, key)
        pairs << [ "(Unknown)", unknown_count ] if unknown_count > 0

        sort_desc(pairs.to_h)
      end

      result = facets.merge(publishing_date: tally_years(scope))
      result
    end

    def count_unknown(document_ids, key)
      return 0 if document_ids.empty?

      documents_with_key = Metadatum.where(document_id: document_ids, key: key).distinct.pluck(:document_id)
      (document_ids - documents_with_key).count
    end

    def tally_years(scope)
      adapter = ActiveRecord::Base.connection.adapter_name.downcase

      rel = Metadatum
        .joins(:document)
        .merge(scope)
        .where(key: "publishing_date")
        .where.not(value: [ nil, "" ])

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
