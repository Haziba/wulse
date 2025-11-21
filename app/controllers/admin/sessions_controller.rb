class Admin::SessionsController < ApplicationController
  skip_before_action :set_current_institution
  layout "active_admin_logged_out"

  def new
  end

  def create
    admin = Admin.find_by(email: params[:email])

    if admin&.authenticate(params[:password])
      session[:admin_id] = admin.id
      redirect_to admin_root_path, notice: "Signed in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:admin_id)
    redirect_to admin_login_path, notice: "Signed out successfully"
  end
end
