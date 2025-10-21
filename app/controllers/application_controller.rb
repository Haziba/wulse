class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  set_current_tenant_through_filter
  before_action :set_current_institution

  helper_method :current_institution, :current_staff, :signed_in?

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

  def current_institution
    ActsAsTenant.current_tenant
  end

  def current_staff
    @current_staff ||= Staff.find_by(id: session[:staff_id]) if session[:staff_id]
  end

  def signed_in?
    current_staff.present?
  end

  def require_signed_in
    unless signed_in?
      redirect_to new_session_path, alert: "You must be signed in to access this page"
    end
  end
end
