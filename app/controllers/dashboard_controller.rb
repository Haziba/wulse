class DashboardController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def index
    last_months_stats = current_institution.institution_stats.where(date: 1.month.ago).first

    @stats = {
      total_documents: current_institution.oers.count,
      active_staff: current_institution.staffs.where(status: 'active').count,
      storage_used: current_institution.storage_used,
    }

    if last_months_stats.present?
      @stats[:documents_change] = current_institution.oers.count - last_months_stats.total_documents
      @stats[:staff_change] = current_institution.staffs.where(status: 'active').count - last_months_stats.active_staff
      @stats[:storage_used_change] = current_institution.storage_used - last_months_stats.storage_used
    end
  end
end
