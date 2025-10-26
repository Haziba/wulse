class LibraryController < ApplicationController
  layout "library"

  def index
    @pagy, @documents = pagy(Library::DocumentFilter.call(params), limit: 10)
    @search_term = params[:search]
    @filters = Library::FilterCounts.new(Oer.all).call
  end
end
