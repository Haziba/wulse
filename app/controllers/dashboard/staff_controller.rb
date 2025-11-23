class Dashboard::StaffController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in
  before_action :full_page_if_no_frame, only: [ :index ]
  before_action :set_staff, only: [ :show, :edit, :update, :deactivate, :activate, :destroy, :reset_password ]

  def index
    staffs = Staff.all
      .order(created_at: :desc)

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
      documents = documents.joins(:metadata).where(metadata: { key: "document_type", value: params[:document_type] })
    end

    @pagy, @documents = pagy(documents.distinct)
  end

  def new
    @staff = Staff.new
  end

  def create
    @staff = Staff.new(staff_params)

    if @staff.save
      password_reset = PasswordReset.create(staff: @staff)
      StaffMailer.welcome_email(@staff, password_reset).deliver_later

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            updated_staff_list,
            add_toast(notice: "Staff member added successfully")
          ]
        end
        format.html { redirect_to dashboard_staff_index_path, notice: "Staff member added successfully!", status: :see_other }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @staff.update(staff_params)
      redirect_to dashboard_staff_index_path, notice: "Staff member updated successfully", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def deactivate
    @staff.update(status: :inactive)
    StaffMailer.deactivation_email(@staff).deliver_later
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
    StaffMailer.activation_email(@staff).deliver_later
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
    if @staff.documents.any?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: add_toast(alert: "Unable to delete staff who has documents")
        end
        format.html { redirect_to dashboard_staff_index_path, alert: "Unable to delete staff who has documents", status: :see_other }
      end
      return
    end

    @staff.destroy
    if turbo_frame_request?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            updated_staff_list(page: params[:page]),
            add_toast(notice: "Staff member deleted successfully")
          ]
        end
      end
    else
      redirect_to dashboard_staff_index_path, notice: "Staff member deleted successfully", status: :see_other
    end
  rescue => e
    Rails.logger.error "Error deleting staff member: #{e.message}"
    render turbo_stream: add_toast(alert: "Error deleting staff member")
  end

  def reset_password
    ResetPasswordService.new(@staff).call

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("staff_#{@staff.id}", partial: "staff_row", locals: { staff: @staff }),
          add_toast(notice: "Password reset email sent to #{@staff.email}")
        ]
      end
    end
  rescue => e
    Rails.logger.error "Error resetting password: #{e.message}"
    render turbo_stream: add_toast(alert: "Error resetting password")
  end

  private

  def updated_staff_list(page: 1)
    staffs = Staff.all.order(created_at: :desc)

    if params[:search].present?
      staffs = staffs.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    if params[:status].present? && params[:status] != "All Status"
      staffs = staffs.where(status: params[:status].downcase)
    end

    @pagy, @staffs = pagy(staffs, page: page)
    turbo_stream.update("staff_list", partial: "staff_list", locals: { staffs: @staffs, pagy: @pagy })
  end

  def staff_params
    params.require(:staff).permit(:name, :email, :status)
  end

  def set_staff
    @staff = Staff.find(params[:id])
  rescue
    Rails.logger.error "Staff not found: #{params[:id]}"
    redirect_to dashboard_staff_index_path, alert: "Staff not found"
  end
end
