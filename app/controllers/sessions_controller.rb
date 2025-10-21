class SessionsController < ApplicationController
  def new
  end

  def create
    staff = Staff.find_by(email: params[:email], institution: current_institution)

    if staff&.authenticate(params[:password])
      session[:staff_id] = staff.id
      staff.update(last_login: Time.current)
      redirect_to dashboard_path, notice: "Welcome back, #{staff.name}!", status: :see_other
    else
      flash.now[:alert] = "Invalid email or password"
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

  def destroy
    session[:staff_id] = nil
    redirect_to root_path, notice: "You have been signed out"
  end
end
