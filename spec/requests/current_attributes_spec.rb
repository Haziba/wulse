require 'rails_helper'

RSpec.describe "Current Attributes", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution, password: "password123") }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "Current.institution" do
    it "is set to the current institution based on subdomain" do
      allow(Current).to receive(:institution=).and_call_original

      get root_path

      expect(Current).to have_received(:institution=).with(institution)
    end
  end

  describe "Current.host" do
    it "is set to the request host" do
      allow(Current).to receive(:host=).and_call_original

      get root_path

      expect(Current).to have_received(:host=).with("#{institution.subdomain}.lvh.me")
    end
  end

  describe "Current.staff" do
    context "when not signed in" do
      it "is set to nil" do
        allow(Current).to receive(:staff=).and_call_original

        get root_path

        expect(Current).to have_received(:staff=).with(nil)
      end
    end

    context "when signed in" do
      it "is set to the current staff member" do
        allow(Current).to receive(:staff=).and_call_original

        post session_path, params: { email: staff.email, password: "password123" }
        get root_path

        expect(Current).to have_received(:staff=).with(staff)
      end
    end
  end
end
