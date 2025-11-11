class LibraryController < ApplicationController
  layout "library"

  def index
    filtered_scope = Library::DocumentFilter.call(params)
    @pagy, @documents = pagy(filtered_scope, limit: 10)
    @search_term = params[:search]
    @filters = Library::FilterCounts.new(filtered_scope).call
    @filtered_count = filtered_scope.count
    @total_count = Document.count
  end

  def read
    @document = Document.find(params[:id])
  end
end
