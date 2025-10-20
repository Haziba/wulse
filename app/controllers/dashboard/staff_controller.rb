class Dashboard::StaffController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

  def index
  end
end
