class SessionsController < ApplicationController
  layout "library"

  def new
    redirect_to dashboard_path if signed_in?
  end

  def create
    staff = Staff.find_by(email: params[:email], institution: Current.institution)

    if staff&.authenticate(params[:password])
      if staff.status == "inactive"
        render_turbo_stream_for_error("Your account has been deactivated. Please contact your administrator.")
      else
        expires = params[:remember_me] == "1" ? 2.weeks.from_now : 24.hours.from_now
        cookies.signed[:staff_id] = { value: staff.id, expires: expires, httponly: true }
        staff.update(last_login: Time.current)
        redirect_to dashboard_path, notice: "Welcome back, #{staff.name}!", status: :see_other
      end
    else
      render_turbo_stream_for_error("Invalid email or password")
    end
  end

  def destroy
    cookies.delete(:staff_id)
    redirect_to root_path, notice: "You have been signed out"
  end

  private

  def render_turbo_stream_for_error(message)
    flash.now[:alert] = message
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("sign_in_form", partial: "sessions/form", locals: { email: params[:email] }),
          turbo_stream.prepend("toast-container-target", partial: "shared/toast_flash")
        ]
      end
      format.html { render :new, status: :unprocessable_content }
    end
  end
end
