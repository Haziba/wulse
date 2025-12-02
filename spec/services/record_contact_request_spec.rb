require 'rails_helper'

RSpec.describe RecordContactRequest do
  let(:params) do
    {
      institution_name: "University of Testing",
      institution_type: "University",
      contact_name: "John Doe",
      email: "john@example.com",
      document_volume: "1,000 - 10,000 documents",
      requirements: "We need custom branding"
    }
  end

  describe "#call" do
    subject(:service) { described_class.new(**params) }

    it "creates a Contact record" do
      expect { service.call }.to change(Contact, :count).by(1)
    end

    it "stores all the provided data in the Contact" do
      service.call

      contact = Contact.last
      expect(contact.institution_name).to eq("University of Testing")
      expect(contact.institution_type).to eq("University")
      expect(contact.contact_name).to eq("John Doe")
      expect(contact.email).to eq("john@example.com")
      expect(contact.document_volume).to eq("1,000 - 10,000 documents")
      expect(contact.requirements).to eq("We need custom branding")
    end

    it "returns the created contact" do
      result = service.call

      expect(result).to be_a(Contact)
      expect(result).to be_persisted
    end

    it "enqueues a notification email" do
      expect { service.call }.to have_enqueued_mail(ContactMailer, :hosting_request)
    end

    it "passes the correct parameters to the mailer" do
      expect { service.call }.to have_enqueued_mail(ContactMailer, :hosting_request).with(
        institution_name: "University of Testing",
        institution_type: "University",
        contact_name: "John Doe",
        email: "john@example.com",
        document_volume: "1,000 - 10,000 documents",
        requirements: "We need custom branding"
      )
    end

    context "with blank optional fields" do
      let(:params) do
        {
          institution_name: "Test Uni",
          institution_type: nil,
          contact_name: "Jane",
          email: "jane@test.com",
          document_volume: nil,
          requirements: nil
        }
      end

      it "creates a contact with nil optional fields" do
        service.call

        contact = Contact.last
        expect(contact.institution_name).to eq("Test Uni")
        expect(contact.institution_type).to be_nil
        expect(contact.requirements).to be_nil
      end
    end

    context "when email sending fails" do
      before do
        allow(ContactMailer).to receive(:hosting_request).and_raise(StandardError, "Mail error")
      end

      it "still creates the contact record" do
        expect {
          service.call rescue nil
        }.to change(Contact, :count).by(1)
      end
    end
  end
end
