require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution, password: "password123") }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /dashboard" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before do
        post session_path, params: {
          email: staff.email,
          password: "password123"
        }
      end

      it "returns http success" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
