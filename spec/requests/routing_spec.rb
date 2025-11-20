require 'rails_helper'

RSpec.describe "Routing", type: :request do
  describe "GET /admin from subdomain" do
    let!(:institution) { create(:institution, subdomain: "test-institution") }

    before do
      host! "test-institution.wulse.org"
    end

    it "redirects to dashboard" do
      get "/admin"
      expect(response).to redirect_to("/dashboard")
    end
  end
end
