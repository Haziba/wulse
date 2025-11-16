class Dashboard::StaffController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in
  before_action :set_staff, only: [:show, :deactivate, :activate, :destroy]

  def index
    staffs = Staff.all

    if params[:search].present?
      staffs = staffs.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    if params[:status].present? && params[:status] != "All Status"
      @status = params[:status].downcase
      staffs = staffs.where(status: @status)
    end

    @pagy, @staffs = pagy(staffs)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("staff_list", partial: "staff_list", locals: { staffs: @staffs, pagy: @pagy })
      end
      format.html
    end
  end

  def show
    documents = @staff.documents.order(created_at: :desc)

    if params[:search].present?
      documents = documents.joins(:metadata).where("metadata.value LIKE ?", "%#{params[:search]}%")
    end

    if params[:document_type].present? && params[:document_type] != "All Types"
      documents = documents.joins(:metadata).where(metadata: { key: 'document_type', value: params[:document_type] })
    end

    @pagy, @documents = pagy(documents.distinct)
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

  def deactivate
    @staff.update(status: :inactive)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("staff_#{@staff.id}", partial: "staff_row", locals: { staff: @staff }),
          add_toast(notice: "Staff member deactivated successfully")
        ]
      end
    end
  rescue => e
    Rails.logger.error "Error deactivating staff member: #{e.message}"
    render turbo_stream: add_toast(alert: "Error deactivating staff member")
  end

  def activate
    @staff.update(status: :active)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("staff_#{@staff.id}", partial: "staff_row", locals: { staff: @staff }),
          add_toast(notice: "Staff member activated successfully")
        ]
      end
    end
  rescue => e
    Rails.logger.error "Error activating staff member: #{e.message}"
    render turbo_stream: add_toast(alert: "Error activating staff member")
  end

  def destroy
    @staff.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("staff_#{@staff.id}"),
          add_toast(notice: "Staff member deleted successfully")
        ]
      end
    end
  rescue => e
    Rails.logger.error "Error deleting staff member: #{e.message}"
    render turbo_stream: add_toast(alert: "Error deleting staff member")
  end

  private

  def staff_params
    params.require(:staff).permit(:name, :email, :status)
  end

  def set_staff
    @staff = Staff.find(params[:id])
  end
end
