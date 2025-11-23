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

      it "highlights staff link in the header" do
        get dashboard_staff_index_path
        expect(response.body).to include('href="' + dashboard_staff_index_path + '"', "Staff", "text-brand-500 border-b-2 border-brand-500")
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

  describe "GET /dashboard/staff/:id" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get dashboard_staff_path(staff)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      let!(:staff_member) { create(:staff, institution: institution, name: "Alice Smith") }
      let!(:other_staff) { create(:staff, institution: institution, name: "Bob Jones") }

      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "returns http success" do
        get dashboard_staff_path(staff_member)
        expect(response).to have_http_status(:success)
      end

      it "displays staff information" do
        get dashboard_staff_path(staff_member)
        expect(response.body).to include(staff_member.name)
        expect(response.body).to include(staff_member.email)
      end

      context "with documents" do
        let!(:doc1) { create(:document, staff: staff_member, institution: institution, title: "Climate Study") }
        let!(:doc2) { create(:document, staff: staff_member, institution: institution, title: "Marine Research") }
        let!(:doc3) { create(:document, staff: staff_member, institution: institution, title: "Energy Analysis") }
        let!(:other_staff_doc) { create(:document, staff: other_staff, institution: institution, title: "Agriculture Report") }

        it "displays only documents from the staff member" do
          get dashboard_staff_path(staff_member)
          expect(response.body).to include("Climate Study")
          expect(response.body).to include("Marine Research")
          expect(response.body).to include("Energy Analysis")
          expect(response.body).not_to include("Agriculture Report")
        end

        context "with search" do
          it "filters documents by search term in title" do
            get dashboard_staff_path(staff_member, search: "Climate")
            expect(response.body).to include("Climate Study")
            expect(response.body).not_to include("Marine Research")
            expect(response.body).not_to include("Energy Analysis")
          end

          it "filters documents by search term in other metadata" do
            doc1.metadata.create!(key: "description", value: "Coastal ecosystems impact")
            doc2.metadata.create!(key: "description", value: "Biodiversity in marine areas")

            get dashboard_staff_path(staff_member, search: "Coastal")
            expect(response.body).to include("Climate Study")
            expect(response.body).not_to include("Marine Research")
          end

          it "returns no results when search doesn't match" do
            get dashboard_staff_path(staff_member, search: "NonExistent")
            expect(response.body).to include("No documents found")
          end
        end

        context "with pagination" do
          before do
            stub_const("Pagy::DEFAULT", Pagy::DEFAULT.merge(limit: 2))
            create_list(:document, 3, staff: staff_member, institution: institution)
          end

          it "paginates documents" do
            get dashboard_staff_path(staff_member)
            expect(response.body).to include("Showing 1 to 2 of")
          end

          it "displays correct documents on page 1" do
            get dashboard_staff_path(staff_member, page: 1)
            expect(response).to have_http_status(:success)
            expect(response.body).to include("Showing 1 to 2 of")
          end

          it "displays correct documents on page 2" do
            get dashboard_staff_path(staff_member, page: 2)
            expect(response).to have_http_status(:success)
            expect(response.body).to include("Showing 3 to")
          end

          it "includes pagination controls" do
            get dashboard_staff_path(staff_member)
            expect(response.body).to include("Previous")
            expect(response.body).to include("Next")
          end
        end

        context "combining search and pagination" do
          before do
            stub_const("Pagy::DEFAULT", Pagy::DEFAULT.merge(limit: 2))
            create(:document, staff: staff_member, institution: institution, title: "Research Paper 1")
            create(:document, staff: staff_member, institution: institution, title: "Research Paper 2")
            create(:document, staff: staff_member, institution: institution, title: "Research Paper 3")
            create(:document, staff: staff_member, institution: institution, title: "Other Document")
          end

          it "paginates filtered results" do
            get dashboard_staff_path(staff_member, search: "Research")
            expect(response.body).to include("Showing 1 to 2 of")
          end
        end
      end

      context "without documents" do
        it "displays no documents message" do
          get dashboard_staff_path(staff_member)
          expect(response.body).to include("No documents found")
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
          expect(response.body).to include(CGI.escapeHTML(valid_params[:staff][:name]))
          expect(response.body).to include(valid_params[:staff][:email])
          expect(response.body).to include('turbo-stream action="update" target="staff_list"')
        end

        it "redirects on html request" do
          post dashboard_staff_index_path, params: valid_params
          expect(response).to redirect_to(dashboard_staff_index_path)
        end

        it "sends a welcome email" do
          expect {
            post dashboard_staff_index_path, params: valid_params
          }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with("StaffMailer", "welcome_email", "deliver_now", { args: [ an_instance_of(Staff), an_instance_of(PasswordReset) ] })
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

  describe "PATCH /dashboard/staff/:id/deactivate" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        patch deactivate_dashboard_staff_path(staff)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      let!(:active_staff) { create(:staff, institution: institution, name: "Active User", status: :active) }

      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "updates the staff status to inactive" do
        expect {
          patch deactivate_dashboard_staff_path(active_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change { active_staff.reload.status }.from("active").to("inactive")
      end

      it "responds with turbo stream" do
        patch deactivate_dashboard_staff_path(active_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "replaces the staff row in the DOM" do
        patch deactivate_dashboard_staff_path(active_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('turbo-stream action="replace" target="staff_' + active_staff.id + '"')
        expect(response.body).to include("Inactive")
      end

      it "includes a success toast notification" do
        patch deactivate_dashboard_staff_path(active_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('turbo-stream action="prepend" target="toast-container-target"')
        expect(response.body).to include("Staff member deactivated successfully")
      end

      it "shows activate button after deactivation" do
        patch deactivate_dashboard_staff_path(active_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("fa-play") # Activate icon
        expect(response.body).not_to include("fa-pause") # Deactivate icon
      end

      it "sends a deactivation email" do
        expect {
          patch deactivate_dashboard_staff_path(active_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with("StaffMailer", "deactivation_email", "deliver_now", { args: [ active_staff ] })
      end
    end
  end

  describe "PATCH /dashboard/staff/:id/activate" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        patch activate_dashboard_staff_path(staff)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      let!(:inactive_staff) { create(:staff, institution: institution, name: "Inactive User", status: :inactive) }

      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "updates the staff status to active" do
        expect {
          patch activate_dashboard_staff_path(inactive_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change { inactive_staff.reload.status }.from("inactive").to("active")
      end

      it "responds with turbo stream" do
        patch activate_dashboard_staff_path(inactive_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "replaces the staff row in the DOM" do
        patch activate_dashboard_staff_path(inactive_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('turbo-stream action="replace" target="staff_' + inactive_staff.id + '"')
        expect(response.body).to include("Active")
      end

      it "includes a success toast notification" do
        patch activate_dashboard_staff_path(inactive_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('turbo-stream action="prepend" target="toast-container-target"')
        expect(response.body).to include("Staff member activated successfully")
      end

      it "shows deactivate button after activation" do
        patch activate_dashboard_staff_path(inactive_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("fa-pause") # Deactivate icon
        expect(response.body).not_to include("fa-play") # Activate icon
      end

      it "sends an activation email" do
        expect {
          patch activate_dashboard_staff_path(inactive_staff), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with("StaffMailer", "activation_email", "deliver_now", { args: [ inactive_staff ] })
      end
    end
  end

  describe "DELETE /dashboard/staff/:id" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        delete dashboard_staff_path(staff)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      let!(:staff_to_delete) { create(:staff, institution: institution, name: "User to Delete") }

      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "deletes the staff member" do
        expect {
          delete dashboard_staff_path(staff_to_delete), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(Staff, :count).by(-1)
      end

      it "responds with turbo stream" do
        delete dashboard_staff_path(staff_to_delete), headers: { "Accept" => "text/vnd.turbo-stream.html", "Turbo-Frame" => "staff_list" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "updates the staff list" do
        delete dashboard_staff_path(staff_to_delete), headers: { "Accept" => "text/vnd.turbo-stream.html", "Turbo-Frame" => "staff_list" }

        expect(response.body).to include('turbo-stream action="update" target="staff_list"')
      end

      it "includes a success toast notification" do
        delete dashboard_staff_path(staff_to_delete), headers: { "Accept" => "text/vnd.turbo-stream.html", "Turbo-Frame" => "staff_list" }

        expect(response.body).to include('turbo-stream action="prepend" target="toast-container-target"')
        expect(response.body).to include("Staff member deleted successfully")
      end

      it "actually removes the staff from the database" do
        staff_id = staff_to_delete.id
        delete dashboard_staff_path(staff_to_delete), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(Staff.find_by(id: staff_id)).to be_nil
      end

      context "when staff has documents" do
        let!(:document) { create(:document, staff: staff_to_delete, institution: institution) }

        it "does not delete the staff member" do
          expect {
            delete dashboard_staff_path(staff_to_delete), headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.not_to change(Staff, :count)
        end

        it "shows an error toast" do
          delete dashboard_staff_path(staff_to_delete), headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.body).to include('turbo-stream action="prepend" target="toast-container-target"')
          expect(response.body).to include("Unable to delete staff who has documents")
        end
      end
    end
  end

  describe "PATCH /dashboard/staff/:id/reset_password" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        patch reset_password_dashboard_staff_path(staff)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      let!(:staff_to_reset) { create(:staff, institution: institution, name: "User to Reset", password: "oldpassword123") }

      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "does not immediately update the staff password" do
        old_password_digest = staff_to_reset.password_digest
        patch reset_password_dashboard_staff_path(staff_to_reset), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(staff_to_reset.reload.password_digest).to eq(old_password_digest)
      end

      it "responds with turbo stream" do
        patch reset_password_dashboard_staff_path(staff_to_reset), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "replaces the staff row in the DOM" do
        patch reset_password_dashboard_staff_path(staff_to_reset), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('turbo-stream action="replace" target="staff_' + staff_to_reset.id + '"')
      end

      it "includes a success toast notification" do
        patch reset_password_dashboard_staff_path(staff_to_reset), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('turbo-stream action="prepend" target="toast-container-target"')
        expect(response.body).to include("Password reset email sent to")
      end

      it "creates a password reset record" do
        expect {
          patch reset_password_dashboard_staff_path(staff_to_reset), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(PasswordReset, :count).by(1)
      end

      it "sends a password reset email" do
        expect {
          patch reset_password_dashboard_staff_path(staff_to_reset), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with("PasswordResetMailer", "reset_password", "deliver_now", { args: [ an_instance_of(PasswordReset) ] })
      end
    end
  end
end
