class Dashboard::StaffController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def index
    @pagy, @staffs = pagy(Staff.all)
  end

  def new
    @staff = Staff.new
  end

  def create
    @staff = Staff.new(staff_params)

    if @staff.save
      total_count = Staff.count
      last_page = (total_count.to_f / Pagy::DEFAULT[:limit]).ceil
      @pagy, @staffs = pagy(Staff.all, page: last_page)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("staff_list", partial: "staff_list", locals: { staffs: @staffs, pagy: @pagy })
        end
        format.html { redirect_to dashboard_staff_index_path(page: last_page), notice: "Staff member added successfully!", status: :see_other }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def staff_params
    params.require(:staff).permit(:name, :email, :status)
  end
end
