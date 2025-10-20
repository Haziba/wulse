class DashboardController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def index
    # These would be real queries in production
    @stats = {
      total_documents: 2847,
      documents_change: "+12%",
      active_staff: 147,
      staff_change: "+5%",
      pending_reviews: 23,
      reviews_change: "-8%",
      storage_used: "847 GB",
      storage_total: "2TB"
    }
  end
end
