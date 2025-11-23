class DashboardController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def index
    last_months_stats = Current.institution.institution_stats.where(date: 1.month.ago).first

    @stats = {
      total_documents: Current.institution.documents.count,
      active_staff: Current.institution.staffs.where(status: "active").count,
      storage_used: Current.institution.storage_used
    }

    if last_months_stats.present?
      @stats[:documents_change] = Current.institution.documents.count - last_months_stats.total_documents
      @stats[:staff_change] = Current.institution.staffs.where(status: "active").count - last_months_stats.active_staff
      @stats[:storage_used_change] = Current.institution.storage_used - last_months_stats.storage_used
    end

    @recent_documents = Current.institution.documents.order(created_at: :desc).includes(:staff, :metadata).limit(3)

    @staff_overview = Current.institution.staffs
      .left_joins(:documents)
      .group("staffs.id")
      .select("staffs.*, COUNT(documents.id) AS documents_count")
      .order("documents_count DESC")
      .limit(3)
  end
end
