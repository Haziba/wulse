class HomeController < ApplicationController
  layout "library"

  def index
    if !current_institution.present?
      redirect_to admin_root_path
    else
      @recent_documents = current_institution.documents.order(created_at: :desc).limit(3)
    end
  end
end
