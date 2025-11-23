class LibraryController < ApplicationController
  layout "library"

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

  def filter_params
    params.permit(Library::FilterCounts::FILTER_KEYS.map { |k| { k => [] } }).to_h
  end
end
