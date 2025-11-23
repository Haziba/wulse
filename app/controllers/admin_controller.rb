class AdminController < ApplicationController
  def index
    @staff = Staff.all
  end
end
