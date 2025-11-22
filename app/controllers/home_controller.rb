class HomeController < ApplicationController
  layout "library"

  def index
    if !Current.institution.present?
      redirect_to admin_root_path
    else
      @recent_documents = Current.institution.documents.order(created_at: :desc).limit(3)
    end
  end
end
