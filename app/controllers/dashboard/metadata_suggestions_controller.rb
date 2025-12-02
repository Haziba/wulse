module Dashboard
  class MetadataSuggestionsController < ApplicationController
    before_action :require_signed_in

    def index
      key = params[:key]

      values = Metadatum
        .joins(:document)
        .where(documents: { institution_id: Current.institution.id })
        .where(key: key)
        .distinct
        .pluck(:value)
        .compact
        .sort

      render json: values
    end
  end
end
