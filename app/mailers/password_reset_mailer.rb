class PasswordResetMailer < ApplicationMailer
  def reset_password(password_reset)
    @password_reset = password_reset
    @staff = password_reset.staff
    @institution = @staff.institution
    @reset_url = edit_password_reset_url(@password_reset.token, subdomain: @institution.subdomain)

    mail to: @staff.email,
         subject: "Password Reset Request"
  end
end
