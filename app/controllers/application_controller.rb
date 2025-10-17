class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  set_current_tenant_through_filter
  before_action :set_current_institution

  private
  def set_current_institution
    return if is_a?(ActiveAdmin::BaseController)

    subdomain = request.subdomain
    institution = Institution.find_by(subdomain: subdomain)
    if institution
      set_current_tenant(institution)
    else
      render plain: "Institution not found", status: :not_found
    end
  end
end
