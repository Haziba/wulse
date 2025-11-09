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

    @recent_documents = current_institution.oers.order(created_at: :desc).includes(:staff, :metadata).limit(3)

    @staff_overview = current_institution.staffs
      .left_joins(:oers)
      .group('staffs.id')
      .select('staffs.*, COUNT(oers.id) AS oers_count')
      .order('oers_count DESC')
      .limit(3)
  end
end
