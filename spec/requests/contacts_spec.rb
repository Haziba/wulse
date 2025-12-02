require 'rails_helper'

RSpec.describe "Contacts", type: :request do
  describe "POST /contact" do
    let(:valid_params) do
      {
        institution_name: "University of Testing",
        institution_type: "University",
        contact_name: "John Doe",
        email: "john@example.com",
        document_volume: "1,000 - 10,000 documents",
        requirements: "We need custom branding"
      }
    end

    it "creates a contact record" do
      expect {
        post contact_path, params: valid_params
      }.to change(Contact, :count).by(1)
    end

    it "stores all the submitted data" do
      post contact_path, params: valid_params

      contact = Contact.last
      expect(contact.institution_name).to eq("University of Testing")
      expect(contact.institution_type).to eq("University")
      expect(contact.contact_name).to eq("John Doe")
      expect(contact.email).to eq("john@example.com")
      expect(contact.document_volume).to eq("1,000 - 10,000 documents")
      expect(contact.requirements).to eq("We need custom branding")
    end

    it "enqueues a notification email" do
      expect {
        post contact_path, params: valid_params
      }.to have_enqueued_mail(ContactMailer, :hosting_request)
    end

    it "responds with turbo stream" do
      post contact_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq Mime[:turbo_stream]
    end

    it "includes a success message in the response" do
      post contact_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("Thank You")
      expect(response.body).to include("Your hosting request has been submitted")
    end

    context "with minimal required data" do
      let(:minimal_params) do
        {
          institution_name: "Test Uni",
          contact_name: "Jane",
          email: "jane@test.com"
        }
      end

      it "creates a contact with optional fields blank" do
        post contact_path, params: minimal_params

        contact = Contact.last
        expect(contact.institution_name).to eq("Test Uni")
        expect(contact.requirements).to be_nil
      end
    end
  end
end
