module Library
  class DocumentFilter
    FILTERABLE_KEYS = %w[document_type department language publishing_date].freeze

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
    end

    def call
      scope = Document.all
      scope = apply_query_filter(scope)
      scope = apply_metadata_filters(scope)
      scope.includes(:preview_image_attachment, :file_attachment).distinct
    end

    private

    attr_reader :params

    def apply_query_filter(scope)
      return scope if params[:q].blank?

      scope.joins(:metadata)
           .where(metadata: { key: "title" })
           .where("metadata.value ILIKE ?", "%#{params[:q]}%")
    end

    def apply_metadata_filters(scope)
      filter_params = params.slice(*FILTERABLE_KEYS)

      filter_params.each do |key, values|
        next if values.blank?

        scope = if key == "publishing_date"
                  apply_publishing_date_filter(scope, values)
        else
                  apply_standard_filter(scope, key, values)
        end
      end

      scope
    end

    def apply_publishing_date_filter(scope, years)
      adapter = ActiveRecord::Base.connection.adapter_name.downcase

      year_expr = case adapter
      when /postgres/
                    "to_char((metadata.value)::date, 'YYYY')"
      when /mysql/
                    "YEAR(CAST(metadata.value AS date))"
      else
                    "strftime('%Y', date(metadata.value))"
      end

      scope.where(
        id: Metadatum.where(key: "publishing_date")
                     .where("#{year_expr} IN (?)", years)
                     .select(:document_id)
      )
    end

    def apply_standard_filter(scope, key, values)
      values = Array(values)

      include_unknown = values.delete("(Unknown)")
      known_values    = values

      metadatum_scope = Metadatum.where(key: key)

      filters = []

      if known_values.present?
        filters << scope.where(
          id: metadatum_scope.where(value: known_values).select(:document_id)
        )
      end

      if include_unknown
        filters << scope.where.not(
          id: metadatum_scope.select(:document_id)
        )
      end

      return scope if filters.empty?

      filters.reduce { |combined, relation| combined.or(relation) }
    end
  end
end
