class LibraryController < ApplicationController
  layout "library"

  def index
    @pagy, @documents = pagy(filtered_documents(params[:search]), limit: 10)
    @search_term = params[:search]
    @filters = Library::FilterCounts.new(filtered_documents(params[:search])).call
  end

  private

  def filtered_documents(search = nil)
    return Oer.all if search.blank?

    Oer.joins(:metadata)
       .where(metadata: { key: 'title' })
       .where("metadata.value LIKE ?", "%#{search}%")
       .distinct
  end
end
