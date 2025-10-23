class Dashboard::DocumentsController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def index
    documents = Oer.all

    if params[:search].present?
      documents = documents.where("name LIKE ?", "%#{params[:search]}%")
    end

    @pagy, @documents = pagy(documents)
  end
end
