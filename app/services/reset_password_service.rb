class ResetPasswordService
  attr_reader :staff, :password_reset

  def initialize(staff)
    @staff = staff
  end

  def call
    @password_reset = staff.password_resets.create!
    PasswordResetMailer.reset_password(password_reset).deliver_later
    password_reset
  end
end
