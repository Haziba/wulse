class DashboardController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def index
    last_months_stats = current_institution.institution_stats.where(date: 1.month.ago).first

    @stats = {
      total_documents: current_institution.documents.count,
      active_staff: current_institution.staffs.where(status: 'active').count,
      storage_used: current_institution.storage_used,
    }

    if last_months_stats.present?
      @stats[:documents_change] = current_institution.documents.count - last_months_stats.total_documents
      @stats[:staff_change] = current_institution.staffs.where(status: 'active').count - last_months_stats.active_staff
      @stats[:storage_used_change] = current_institution.storage_used - last_months_stats.storage_used
    end

    @recent_documents = current_institution.documents.order(created_at: :desc).includes(:staff, :metadata).limit(3)

    @staff_overview = current_institution.staffs
      .left_joins(:documents)
      .group('staffs.id')
      .select('staffs.*, COUNT(documents.id) AS documents_count')
      .order('documents_count DESC')
      .limit(3)
  end
end
