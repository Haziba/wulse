require 'rails_helper'

RSpec.describe "Pages", type: :request do
  let(:institution) { create(:institution) }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /terms" do
    it "returns http success" do
      get terms_path
      expect(response).to have_http_status(:success)
    end

    it "displays Terms of Service heading" do
      get terms_path
      expect(response.body).to include("Terms of Service")
    end

    it "displays the institution name" do
      get terms_path
      expect(response.body).to include(institution.name.titleize)
    end
  end

  describe "GET /privacy" do
    it "returns http success" do
      get privacy_path
      expect(response).to have_http_status(:success)
    end

    it "displays Privacy Policy heading" do
      get privacy_path
      expect(response.body).to include("Privacy Policy")
    end

    it "displays the institution name" do
      get privacy_path
      expect(response.body).to include(institution.name.titleize)
    end
  end
end
