require 'rails_helper'

RSpec.describe "Dashboard::Staff", type: :request do
  let(:institution) { create(:institution) }
  let(:other_institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:inactive_staff) { create(:staff, institution: institution, status: :inactive) }
  let!(:institution_staff_1) { create(:staff, institution: institution, name: "Alice Smith", email: "alice@test.com", status: :active, last_login: 1.hour.ago) }
  let!(:institution_staff_2) { create(:staff, institution: institution, name: "Bob Jones", email: "bob@test.com", status: :inactive, last_login: 2.days.ago) }
  let!(:other_institution_staff) { create(:staff, institution: other_institution, name: "Charlie Brown", email: "charlie@other.com") }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /dashboard/staff" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get dashboard_staff_index_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "returns http success" do
        get dashboard_staff_index_path
        expect(response).to have_http_status(:success)
      end

      it "displays only staff from the current institution" do
        get dashboard_staff_index_path
        expect(response.body).to include("Alice Smith")
        expect(response.body).to include("Bob Jones")
        expect(response.body).to include("alice@test.com")
        expect(response.body).to include("bob@test.com")
        expect(response.body).not_to include("Charlie Brown")
        expect(response.body).not_to include("charlie@other.com")
      end

      it "displays staff status" do
        get dashboard_staff_index_path
        expect(response.body).to include("Active")
        expect(response.body).to include("Inactive")
      end

      it "displays last login times" do
        get dashboard_staff_index_path
        expect(response.body).to match(/\d+\s+(hour|hours)\s+ago/)
        expect(response.body).to match(/\d+\s+(day|days)\s+ago/)
      end
    end
  end
end
