class HomeController < ApplicationController
  def index
    if !current_institution.present?
      redirect_to admin_root_path
    end
  end
end
