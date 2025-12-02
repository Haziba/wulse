class RecordContactRequest
  def initialize(institution_name:, institution_type:, contact_name:, email:, document_volume:, requirements:)
    @institution_name = institution_name
    @institution_type = institution_type
    @contact_name = contact_name
    @email = email
    @document_volume = document_volume
    @requirements = requirements
  end

  def call
    contact = create_contact
    send_notification_email
    contact
  end

  private

  def create_contact
    Contact.create!(
      institution_name: @institution_name,
      institution_type: @institution_type,
      contact_name: @contact_name,
      email: @email,
      document_volume: @document_volume,
      requirements: @requirements
    )
  end

  def send_notification_email
    ContactMailer.hosting_request(
      institution_name: @institution_name,
      institution_type: @institution_type,
      contact_name: @contact_name,
      email: @email,
      document_volume: @document_volume,
      requirements: @requirements
    ).deliver_later
  end
end
