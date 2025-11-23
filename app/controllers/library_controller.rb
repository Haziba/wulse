class LibraryController < ApplicationController
  layout "library"

  before_action :decode_filter_params, only: :index

  def index
    filtered_scope = Library::DocumentFilter.call(params)
    @pagy, @documents = pagy(filtered_scope, limit: 10)
    @query = params[:q]
    @filters = Library::FilterCounts.new(filtered_scope, selected_filters: filter_params).call
    @filtered_count = filtered_scope.count
    @total_count = Document.count

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def read
    @document = Document.find(params[:id])
  end

  private

  def decode_filter_params
    return if params[:f].blank?

    Library::FilterParams.decode(params[:f]).each do |key, values|
      params[key] = values
    end
  end

  def filter_params
    return {} if params[:f].blank?

    Library::FilterParams.decode(params[:f]) || {}
  end
end
