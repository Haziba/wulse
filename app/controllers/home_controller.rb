class HomeController < ApplicationController
  layout "library", except: :landing

  def index
    if !Current.institution.present?
      render :landing, layout: false
    else
      @recent_documents = Current.institution.documents
                                  .includes(:preview_image_attachment, :file_attachment)
                                  .order(created_at: :desc)
                                  .limit(3)
    end
  end
end
