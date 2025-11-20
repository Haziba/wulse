require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when accessing from root domain" do
      before do
        host! "wulse.org"
      end

      it "redirects to admin" do
        get root_path
        expect(response).to redirect_to(admin_root_path)
      end
    end

    context "when accessing from a non-existing institution subdomain" do
      before do
        host! "non-existing.wulse.org"
      end

      it "returns not found" do
        get root_path
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Institution not found")
      end
    end

    context "when accessing from an existing institution subdomain" do
      let!(:institution) { create(:institution, subdomain: "test-institution") }

      before do
        host! "test-institution.wulse.org"
      end

      it "renders the home page" do
        get root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
