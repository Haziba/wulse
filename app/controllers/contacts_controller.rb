class ContactsController < ApplicationController
  skip_before_action :set_current_institution
  layout false

  def create
    RecordContactRequest.new(
      institution_name: params[:institution_name],
      institution_type: params[:institution_type],
      contact_name: params[:contact_name],
      email: params[:email],
      document_volume: params[:document_volume],
      requirements: params[:requirements]
    ).call

    respond_to do |format|
      format.turbo_stream
    end
  end
end
