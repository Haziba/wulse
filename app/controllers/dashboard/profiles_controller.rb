class Dashboard::ProfilesController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def edit
    @staff = current_staff
  end

  def update
    @staff = current_staff

    # If changing password, verify current password first
    if profile_params[:password].present?
      unless @staff.authenticate(params[:current_password])
        flash.now[:alert] = "Current password is incorrect"
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("profile_form", partial: "form", locals: { staff: @staff }),
              turbo_stream.prepend("toast-container-target", partial: "shared/toast_flash")
            ]
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
        return
      end
    end

    # Handle avatar removal
    if params[:remove_avatar] == "1"
      @staff.avatar.purge
      @staff.reload
    end

    # Build params hash excluding current_password (not a staff attribute)
    update_params = profile_params.except(:current_password)

    # Remove password params if blank
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @staff.update(update_params)
      @staff.reload # Ensure avatar attachment is loaded
      flash.now[:notice] = "Profile updated successfully!"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("profile_form", partial: "form", locals: { staff: @staff }),
            turbo_stream.replace("user_profile_menu", partial: "shared/user_profile_menu", locals: { staff: @staff }),
            turbo_stream.prepend("toast-container-target", partial: "shared/toast_flash")
          ]
        end
        format.html { redirect_to edit_dashboard_profile_path, notice: "Profile updated successfully!" }
      end
    else
      flash.now[:alert] = "There were errors updating your profile"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("profile_form", partial: "form", locals: { staff: @staff }),
            turbo_stream.prepend("toast-container-target", partial: "shared/toast_flash")
          ]
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def profile_params
    params.require(:staff).permit(:name, :current_password, :password, :password_confirmation, :avatar)
  end
end
