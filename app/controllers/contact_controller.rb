class ContactController < ApplicationController
  def create
    @institution_name = params[:institution_name]
    @institution_type = params[:institution_type]
    @contact_name = params[:contact_name]
    @email = params[:email]
    @document_volume = params[:document_volume]
    @requirements = params[:requirements]

    ContactMailer.hosting_request(
      institution_name: @institution_name,
      institution_type: @institution_type,
      contact_name: @contact_name,
      email: @email,
      document_volume: @document_volume,
      requirements: @requirements
    ).deliver_later

    respond_to do |format|
      format.turbo_stream
    end
  end
end
