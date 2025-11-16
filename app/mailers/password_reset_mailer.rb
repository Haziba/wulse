class PasswordResetMailer < ApplicationMailer
  def reset_password(password_reset)
    @password_reset = password_reset
    @staff = password_reset.staff
    @reset_url = edit_password_reset_url(@password_reset.token, subdomain: @staff.institution.subdomain)

    mail to: @staff.email,
         subject: "Password Reset Request"
  end
end
