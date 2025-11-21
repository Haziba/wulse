class StaffMailer < ApplicationMailer
  def welcome_email(staff, password_reset)
    @staff = staff
    @institution = staff.institution
    @password_reset = password_reset
    @set_password_url = edit_password_reset_url(@password_reset.token, subdomain: @institution.subdomain)

    mail to: @staff.email,
         subject: "Welcome to the #{@institution.name} Digital Library!"
  end

  def deactivation_email(staff)
    @staff = staff
    @institution = staff.institution

    mail to: @staff.email,
         subject: "Your Account Has Been Deactivated"
  end
end
