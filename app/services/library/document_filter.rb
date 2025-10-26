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
      scope = Oer.all
      scope = apply_search_filter(scope)
      scope = apply_metadata_filters(scope)
      scope.distinct
    end

    private

    attr_reader :params

    def apply_search_filter(scope)
      return scope if params[:search].blank?

      scope.joins(:metadata)
           .where(metadata: { key: 'title' })
           .where("metadata.value LIKE ?", "%#{params[:search]}%")
    end

    def apply_metadata_filters(scope)
      filter_params = params.slice(*FILTERABLE_KEYS)

      filter_params.each do |key, values|
        next if values.blank?

        scope = if key == 'publishing_date'
                  apply_publishing_date_filter(scope, values)
                else
                  apply_standard_filter(scope, key, values)
                end
      end

      scope
    end

    def apply_publishing_date_filter(scope, years)
      scope.where(
        id: Metadatum.where(key: 'publishing_date')
                     .where("strftime('%Y', date(value)) IN (?)", years)
                     .select(:oer_id)
      )
    end

    def apply_standard_filter(scope, key, values)
      scope.where(
        id: Metadatum.where(key: key, value: values).select(:oer_id)
      )
    end
  end
end
