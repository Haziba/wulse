require "rails_helper"

RSpec.describe "Profile", type: :system do
  before do
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution) }
  let!(:staff) { create(:staff, institution: institution, email: "user@example.com", password: "password123", name: "John Doe") }

  def sign_in
    visit new_session_path
    fill_in "Email", with: "user@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    expect(page).to have_current_path(dashboard_path)
  end

  describe "updating profile" do
    before { sign_in }

    it "updates the profile picture" do
      visit edit_dashboard_profile_path

      expect(page).to have_content("Edit Profile")

      # Upload a new avatar
      attach_file "staff[avatar]", Rails.root.join("spec/fixtures/files/avatar.jpg"), visible: false

      click_button "Save Changes"

      expect(page).to have_content("Profile updated successfully!")

      # Verify avatar is attached
      staff.reload
      expect(staff.avatar).to be_attached
    end

    it "updates the name" do
      visit edit_dashboard_profile_path

      fill_in "Name", with: "Jane Smith"

      click_button "Save Changes"

      expect(page).to have_content("Profile updated successfully!")

      staff.reload
      expect(staff.name).to eq("Jane Smith")
    end

    it "updates the password with correct current password" do
      visit edit_dashboard_profile_path

      fill_in "Current Password", with: "password123"
      fill_in "New Password", with: "newpassword456"
      fill_in "Confirm New Password", with: "newpassword456"

      click_button "Save Changes"

      expect(page).to have_content("Profile updated successfully!")

      # Verify password was changed by signing out and back in
      page.driver.with_playwright_page { |p| p.context.clear_cookies }

      visit new_session_path
      expect(page).to have_content("Welcome Back")
      fill_in "Email Address", with: "user@example.com"
      fill_in "Password", with: "newpassword456"
      click_button "Sign In"

      expect(page).to have_current_path(dashboard_path)
    end

    it "updates name without changing password when password fields are blank" do
      original_password_digest = staff.password_digest

      visit edit_dashboard_profile_path

      fill_in "Name", with: "Updated Name"
      # Leave password fields blank

      click_button "Save Changes"

      expect(page).to have_content("Profile updated successfully!")

      staff.reload
      expect(staff.name).to eq("Updated Name")
      expect(staff.password_digest).to eq(original_password_digest)

      # Verify old password still works
      page.driver.with_playwright_page { |p| p.context.clear_cookies }

      visit new_session_path
      expect(page).to have_content("Welcome Back")
      fill_in "Email Address", with: "user@example.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"

      expect(page).to have_current_path(dashboard_path)
    end

    it "shows error when current password is incorrect" do
      visit edit_dashboard_profile_path

      fill_in "Current Password", with: "wrongpassword"
      fill_in "New Password", with: "newpassword456"
      fill_in "Confirm New Password", with: "newpassword456"

      click_button "Save Changes"

      expect(page).to have_content("Current password is incorrect")

      # Password should not have changed
      staff.reload
      expect(staff.authenticate("password123")).to be_truthy
      expect(staff.authenticate("newpassword456")).to be_falsey
    end

    it "validates password length" do
      visit edit_dashboard_profile_path

      fill_in "Current Password", with: "password123"
      fill_in "New Password", with: "short"
      fill_in "Confirm New Password", with: "short"

      click_button "Save Changes"

      expect(page).to have_content("is too short (minimum is 8 characters)")
    end

    it "validates password confirmation matches" do
      visit edit_dashboard_profile_path

      fill_in "Current Password", with: "password123"
      fill_in "New Password", with: "newpassword456"
      fill_in "Confirm New Password", with: "differentpassword"

      click_button "Save Changes"

      expect(page).to have_content("There were errors updating your profile")

      # Password should not have changed
      staff.reload
      expect(staff.authenticate("password123")).to be_truthy
      expect(staff.authenticate("newpassword456")).to be_falsey
    end

    it "validates name presence" do
      visit edit_dashboard_profile_path

      fill_in "Name", with: ""

      click_button "Save Changes"

      expect(page).to have_content("can't be blank")
    end
  end

  describe "updating profile picture" do
    before { sign_in }

    it "removes the profile picture" do
      # First, add an avatar
      staff.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/avatar.jpg")),
        filename: "avatar.jpg",
        content_type: "image/jpeg"
      )
      staff.reload

      visit edit_dashboard_profile_path

      expect(staff.avatar).to be_attached

      # Click the Remove button
      click_button "Remove"

      click_button "Save Changes"

      expect(page).to have_content("Profile updated successfully!")

      staff.reload
      expect(staff.avatar).not_to be_attached
    end

    it "displays initials when no avatar is present" do
      visit edit_dashboard_profile_path

      # Should display initials (JD for John Doe)
      within("[data-controller='avatar-preview']") do
        expect(page).to have_content("JD")
      end
    end
  end

  describe "updating multiple fields at once" do
    before { sign_in }

    it "updates name, avatar, and password together" do
      visit edit_dashboard_profile_path

      fill_in "Name", with: "Updated User"
      attach_file "staff[avatar]", Rails.root.join("spec/fixtures/files/avatar.jpg"), visible: false
      fill_in "Current Password", with: "password123"
      fill_in "New Password", with: "newsecurepass"
      fill_in "Confirm New Password", with: "newsecurepass"

      click_button "Save Changes"

      expect(page).to have_content("Profile updated successfully!")

      staff.reload
      expect(staff.name).to eq("Updated User")
      expect(staff.avatar).to be_attached
      expect(staff.authenticate("newsecurepass")).to be_truthy
    end
  end
end
