class SessionsController < ApplicationController
  def new
  end

  def create
    staff = Staff.find_by(email: params[:email], institution: current_institution)

    if staff&.authenticate(params[:password])
      session[:staff_id] = staff.id
      redirect_to root_path, notice: "Welcome back, #{staff.name}!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:staff_id] = nil
    redirect_to root_path, notice: "You have been signed out"
  end
end
