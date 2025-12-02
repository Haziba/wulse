class ContactMailer < ApplicationMailer
  default from: "Wulse <noreply@wulse.org>"

  def hosting_request(institution_name:, institution_type:, contact_name:, email:, document_volume:, requirements:)
    @institution_name = institution_name
    @institution_type = institution_type
    @contact_name = contact_name
    @email = email
    @document_volume = document_volume
    @requirements = requirements

    admin_emails = Admin.pluck(:email)

    mail(
      to: admin_emails,
      reply_to: email,
      subject: "Hosting Request from #{institution_name}"
    )
  end
end
