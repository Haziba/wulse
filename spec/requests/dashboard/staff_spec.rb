require 'rails_helper'

RSpec.describe "Dashboard::Staff", type: :request do
  let(:institution) { create(:institution) }
  let(:other_institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

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
      let!(:institution_staff_1) { create(:staff, institution: institution, name: "Alice Smith", email: "alice@test.com", status: :active, last_login: 1.hour.ago) }
      let!(:institution_staff_2) { create(:staff, institution: institution, name: "Bob Jones", email: "bob@test.com", status: :inactive, last_login: 2.days.ago) }
      let!(:other_institution_staff) { create(:staff, institution: other_institution, name: "Charlie Brown", email: "charlie@other.com") }

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

      context "with pagination" do
        before do
          stub_const("Pagy::DEFAULT", Pagy::DEFAULT.merge(limit: 2))
          create_list(:staff, 3, institution: institution)
        end

        it "paginates staff members" do
          get dashboard_staff_index_path
          expect(response.body).to include("Showing 1 to 2 of")
        end

        it "displays correct staff on page 1" do
          get dashboard_staff_index_path(page: 1)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Showing 1 to 2 of")
        end

        it "displays correct staff on page 2" do
          get dashboard_staff_index_path(page: 2)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Showing 3 to")
        end

        it "includes pagination controls" do
          get dashboard_staff_index_path
          expect(response.body).to include("Previous")
          expect(response.body).to include("Next")
        end
      end

      context "with filtering" do
        it "filters staff by search term matching name" do
          get dashboard_staff_index_path(search: "Alice")
          expect(response.body).to include("Alice Smith")
          expect(response.body).not_to include("Bob Jones")
        end

        it "filters staff by search term matching email" do
          get dashboard_staff_index_path(search: "bob@test.com")
          expect(response.body).to include("Bob Jones")
          expect(response.body).not_to include("Alice Smith")
        end

        it "filters staff by status" do
          get dashboard_staff_index_path(status: "active")
          expect(response.body).to include("Alice Smith")
          expect(response.body).not_to include("Bob Jones")
        end

        it "filters staff by inactive status" do
          get dashboard_staff_index_path(status: "inactive")
          expect(response.body).to include("Bob Jones")
          expect(response.body).not_to include("Alice Smith")
        end

        it "shows all staff when status is 'All Status'" do
          get dashboard_staff_index_path(status: "All Status")
          expect(response.body).to include("Alice Smith")
          expect(response.body).to include("Bob Jones")
        end

        it "combines search and status filters" do
          get dashboard_staff_index_path(search: "Alice", status: "active")
          expect(response.body).to include("Alice Smith")
          expect(response.body).not_to include("Bob Jones")
        end

        it "returns no results when filters don't match" do
          get dashboard_staff_index_path(search: "Alice", status: "inactive")
          expect(response.body).not_to include("Alice Smith")
          expect(response.body).not_to include("Bob Jones")
        end
      end
    end
  end

  describe "POST /dashboard/staff" do
    context "when authenticated" do
      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      context "with valid parameters" do
        let(:valid_params) do
          {
            staff: {
              name: Faker::Name.name,
              email: Faker::Internet.email,
            }
          }
        end

        it "creates a new staff member" do
          expect {
            post dashboard_staff_index_path, params: valid_params
          }.to change(Staff, :count).by(1)
        end

        it "responds with turbo stream that updates the staff list" do
          post dashboard_staff_index_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include(valid_params[:staff][:name])
          expect(response.body).to include(valid_params[:staff][:email])
          expect(response.body).to include('turbo-stream action="replace" target="staff_list"')
        end

        it "redirects on html request to last page" do
          post dashboard_staff_index_path, params: valid_params
          expect(response).to redirect_to(dashboard_staff_index_path(page: 1))
        end

      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            staff: {
              name: "",
              email: ""
            }
          }
        end

        it "does not create a new staff member" do
          expect {
            post dashboard_staff_index_path, params: invalid_params
          }.not_to change(Staff, :count)
        end

        it "renders the form again" do
          post dashboard_staff_index_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
