class LibraryController < ApplicationController
  layout "library"

  def index
    documents = Oer.all

    if params[:search].present?
      documents = documents.where("name LIKE ?", "%#{params[:search]}%")
    end

    @pagy, @documents = pagy(documents, limit: 10)
    @search_term = params[:search]
  end
end
