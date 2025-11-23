require "rails_helper"

RSpec.describe "Dashboard Staff", type: :system do
  include ActiveJob::TestHelper

  before do
    driven_by(:selenium_headless)
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution, branding_colour: "#1e40af") }
  let!(:admin) { create(:staff, institution: institution, email: "admin@example.com", password: "password123", name: "Admin User") }

  before do
    visit new_session_path
    fill_in "Email", with: "admin@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    visit dashboard_staff_index_path
  end

  describe "staff list" do
    let!(:staff_alice) { create(:staff, institution: institution, name: "Alice Smith", email: "alice@example.com", status: :active) }
    let!(:staff_bob) { create(:staff, institution: institution, name: "Bob Jones", email: "bob@example.com", status: :inactive) }

    before { visit dashboard_staff_index_path }

    it "displays all staff members" do
      expect(page).to have_content("Staff Management")
      expect(page).to have_content("Alice Smith")
      expect(page).to have_content("Bob Jones")
      expect(page).to have_content("Admin User")
    end

    it "displays staff status badges" do
      expect(page).to have_content("Active")
      expect(page).to have_content("Inactive")
    end
  end

  describe "filtering staff" do
    let!(:alice_staff) { create(:staff, institution: institution, name: "Alice Johnson", status: :active) }
    let!(:bob_staff) { create(:staff, institution: institution, name: "Bob Williams", status: :inactive) }

    it "filters by search term via URL" do
      visit "#{dashboard_staff_index_path}?search=Alice"

      expect(page).to have_field("search", with: "Alice")

      within("#staff_list") do
        expect(page).to have_content("Alice Johnson")
        expect(page).not_to have_content("Bob Williams")
      end
    end

    it "filters by status" do
      visit dashboard_staff_index_path
      select "Inactive", from: "status"

      within("#staff_list") do
        expect(page).to have_content("Bob Williams", wait: 5)
        expect(page).not_to have_content("Alice Johnson")
      end
    end

    it "loads page with filter from URL" do
      visit dashboard_staff_index_path(status: "Inactive")

      within("#staff_list") do
        expect(page).to have_content("Bob Williams")
        expect(page).not_to have_content("Alice Johnson")
      end
      expect(page).to have_select("status", selected: "Inactive")
    end
  end

  describe "adding a staff member" do
    it "opens modal and creates new staff member" do
      click_link "Add Staff"

      within("dialog") do
        fill_in "Full Name", with: "New Staff Member"
        fill_in "Email Address", with: "newstaff@example.com"
        click_button "Add Staff Member"
      end

      expect(page).to have_content("New Staff Member")
      expect(page).to have_content("newstaff@example.com")
    end

    it "sends welcome email with password reset link" do
      click_link "Add Staff"

      within("dialog") do
        fill_in "Full Name", with: "Email Test Staff"
        fill_in "Email Address", with: "emailtest@example.com"
        click_button "Add Staff Member"
      end

      perform_enqueued_jobs

      email = ActionMailer::Base.deliveries.last
      expect(email).not_to be_nil
      expect(email.to).to include("emailtest@example.com")
    end
  end

  describe "reset password" do
    let!(:staff_member) { create(:staff, institution: institution, name: "Password Reset Staff", email: "resetme@example.com") }

    before do
      ActionMailer::Base.deliveries.clear
      visit dashboard_staff_index_path
    end

    it "sends password reset email" do
      accept_confirm("Are you sure you want to reset staff member a reset password email?") do
        find("button[aria-label='Reset password for Password Reset Staff']").click
      end

      expect(page).to have_content("Password reset email sent")

      perform_enqueued_jobs

      email = ActionMailer::Base.deliveries.last
      expect(email).not_to be_nil
      expect(email.to).to include("resetme@example.com")
      expect(email.subject).to include("Reset")
    end
  end

  describe "deactivating staff" do
    let!(:active_staff) { create(:staff, institution: institution, name: "Deactivate Me", email: "deactivate@example.com", status: :active) }

    before do
      ActionMailer::Base.deliveries.clear
      visit dashboard_staff_index_path
    end

    it "updates the HTML to show inactive status" do
      within("#staff_#{active_staff.id}") do
        expect(page).to have_content("Active")

        accept_confirm("Are you sure you want to deactivate this staff member?") do
          find("button[aria-label='Deactivate Deactivate Me']").click
        end

        expect(page).to have_content("Inactive")
      end
    end

    it "sends deactivation email" do
      accept_confirm("Are you sure you want to deactivate this staff member?") do
        find("button[aria-label='Deactivate Deactivate Me']").click
      end

      expect(page).to have_content("Staff member deactivated successfully")

      perform_enqueued_jobs

      email = ActionMailer::Base.deliveries.last
      expect(email).not_to be_nil
      expect(email.to).to include("deactivate@example.com")
    end

    it "sets the user to inactive in database" do
      accept_confirm("Are you sure you want to deactivate this staff member?") do
        find("button[aria-label='Deactivate Deactivate Me']").click
      end

      expect(page).to have_content("Inactive")
      expect(active_staff.reload.status).to eq("inactive")
    end
  end

  describe "activating staff" do
    let!(:inactive_staff) { create(:staff, institution: institution, name: "Activate Me", email: "activate@example.com", status: :inactive) }

    before do
      ActionMailer::Base.deliveries.clear
      visit dashboard_staff_index_path
    end

    it "updates the HTML to show active status" do
      within("#staff_#{inactive_staff.id}") do
        expect(page).to have_content("Inactive")

        accept_confirm("Are you sure you want to activate this staff member?") do
          find("button[aria-label='Activate Activate Me']").click
        end

        expect(page).to have_content("Active")
      end
    end

    it "sends activation email" do
      accept_confirm("Are you sure you want to activate this staff member?") do
        find("button[aria-label='Activate Activate Me']").click
      end

      expect(page).to have_content("Staff member activated successfully")

      perform_enqueued_jobs

      email = ActionMailer::Base.deliveries.last
      expect(email).not_to be_nil
      expect(email.to).to include("activate@example.com")
    end

    it "sets the user to active in database" do
      accept_confirm("Are you sure you want to activate this staff member?") do
        find("button[aria-label='Activate Activate Me']").click
      end

      expect(page).to have_content("Staff member activated successfully")
      expect(inactive_staff.reload.status).to eq("active")
    end
  end

  describe "viewing staff" do
    let!(:staff_member) { create(:staff, institution: institution, name: "View Me Staff", email: "viewme@example.com", status: :active) }

    it "links to view page from staff list" do
      visit dashboard_staff_index_path
      click_link "View Me Staff"

      expect(page).to have_current_path(dashboard_staff_path(staff_member))
    end

    it "displays staff metadata on view page" do
      visit dashboard_staff_path(staff_member)

      expect(page).to have_content("View Me Staff")
      expect(page).to have_content("viewme@example.com")
      expect(page).to have_content("Active")
      expect(page).to have_content("Documents:")
      expect(page).to have_content("Joined:")
      expect(page).to have_content("Last login:")
    end
  end

  describe "editing staff" do
    let!(:staff_member) { create(:staff, institution: institution, name: "Edit Me Staff", email: "editme@example.com") }

    it "links to edit page from staff list" do
      visit dashboard_staff_index_path
      find("a[aria-label='Edit Edit Me Staff']").click

      expect(page).to have_current_path(edit_dashboard_staff_path(staff_member))
      expect(page).to have_content("Edit Staff Member")
    end

    it "saves changes to staff member" do
      visit edit_dashboard_staff_path(staff_member)

      fill_in "Full Name", with: "Updated Name"
      fill_in "Email Address", with: "updated@example.com"
      click_button "Save Changes"

      expect(page).to have_current_path(dashboard_staff_index_path)
      expect(page).to have_content("Updated Name")
      expect(page).to have_content("updated@example.com")
    end

    it "allows changing status" do
      visit edit_dashboard_staff_path(staff_member)

      select "Inactive", from: "Status"
      click_button "Save Changes"

      expect(staff_member.reload.status).to eq("inactive")
    end
  end

  describe "deleting staff" do
    let!(:staff_to_delete) { create(:staff, institution: institution, name: "Delete Me Staff", email: "deleteme@example.com") }

    before { visit dashboard_staff_index_path }

    it "removes staff from the page" do
      expect(page).to have_content("Delete Me Staff")

      accept_confirm("Are you sure you want to delete this staff member? This action cannot be undone.") do
        find("button[aria-label='Delete Delete Me Staff']").click
      end

      expect(page).not_to have_content("Delete Me Staff")
    end

    it "deletes staff from database" do
      staff_id = staff_to_delete.id

      accept_confirm("Are you sure you want to delete this staff member? This action cannot be undone.") do
        find("button[aria-label='Delete Delete Me Staff']").click
      end

      expect(page).not_to have_content("Delete Me Staff")
      expect(Staff.find_by(id: staff_id)).to be_nil
    end

    context "when staff has documents" do
      let!(:document) { create(:document, institution: institution, staff: staff_to_delete, title: "Staff's Document") }

      it "prevents deletion and shows error" do
        accept_confirm("Are you sure you want to delete this staff member? This action cannot be undone.") do
          find("button[aria-label='Delete Delete Me Staff']").click
        end

        expect(page).to have_content("Delete Me Staff")
        expect(page).to have_content("Unable to delete staff who has documents")
      end
    end
  end
end
