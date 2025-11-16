class PasswordResetsController < ApplicationController
  before_action :set_password_reset_and_institution, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def edit
  end

  def update
    if @password_reset.staff.update(password: password_params[:password], password_confirmation: password_params[:password_confirmation])
      @password_reset.destroy

      redirect_to new_session_path, notice: "Your password has been reset successfully. Please sign in."
    else
      flash.now[:alert] = @password_reset.staff.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_password_reset_and_institution
    @password_reset = PasswordReset.find_by(token: params[:token])

    unless @password_reset
      redirect_to new_session_url, alert: "Invalid or expired password reset link.", allow_other_host: true and return
    end

    set_current_tenant(@password_reset.staff.institution)
  end

  def check_expiration
    if @password_reset&.expired?
      institution_subdomain = @password_reset.staff.institution.subdomain
      @password_reset.destroy
      redirect_to new_session_url(subdomain: institution_subdomain), alert: "Password reset link has expired. Please request a new one.", allow_other_host: true
    end
  end

  def password_params
    params.require(:password_reset).permit(:password, :password_confirmation)
  end
end
