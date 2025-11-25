require "rails_helper"

RSpec.describe "Sessions", type: :system do
  include ActiveJob::TestHelper
  before do
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution, branding_colour: "#1e40af") }
  let!(:staff) { create(:staff, institution: institution, email: "test@example.com", password: "password123") }

  describe "sign in page" do
    it "displays the sign in form" do
      visit new_session_path

      expect(page).to have_content("Welcome Back")
      expect(page).to have_content("Sign in to manage your digital library")
      expect(page).to have_field("Email")
      expect(page).to have_field("Password")
      expect(page).to have_button("Sign In")
      expect(page).to have_link("Forgot password?")
    end

    it "signs in with valid credentials" do
      visit new_session_path

      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"

      expect(page).to have_current_path(dashboard_path)
    end

    it "shows error with invalid credentials" do
      visit new_session_path

      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "wrongpassword"
      click_button "Sign In"

      expect(page).to have_content("Invalid email or password")
    end

    it "links to forgot password page" do
      visit new_session_path

      click_link "Forgot password?"

      expect(page).to have_current_path(new_password_reset_path)
      expect(page).to have_content("Forgot Password")
    end
  end

  describe "forgot password page" do
    it "displays the forgot password form" do
      visit new_password_reset_path

      expect(page).to have_content("Forgot Password")
      expect(page).to have_content("Enter your email to receive reset instructions")
      expect(page).to have_field("Email")
      expect(page).to have_button("Send Reset Instructions")
      expect(page).to have_link("Back to Sign In")
    end

    it "submits password reset request and sends email" do
      visit new_password_reset_path

      fill_in "Email", with: "test@example.com"
      click_button "Send Reset Instructions"

      expect(page).to have_content("If an account exists")

      perform_enqueued_jobs

      email = ActionMailer::Base.deliveries.last
      expect(email).not_to be_nil
      expect(email.to).to include("test@example.com")
      expect(email.subject).to include("Reset")
    end

    it "links back to sign in" do
      visit new_password_reset_path

      click_link "Back to Sign In"

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "reset password page" do
    let!(:password_reset) { create(:password_reset, staff: staff) }

    it "displays the reset password form" do
      visit edit_password_reset_path(password_reset.token)

      expect(page).to have_content("Reset Password")
      expect(page).to have_content("Enter your new password below")
      expect(page).to have_field("New Password")
      expect(page).to have_field("Confirm New Password")
      expect(page).to have_button("Reset Password")
      expect(page).to have_link("Back to Sign In")
    end

    it "resets password and allows sign in with new password" do
      visit edit_password_reset_path(password_reset.token)

      fill_in "New Password", with: "newpassword123"
      fill_in "Confirm New Password", with: "newpassword123"
      click_button "Reset Password"

      expect(page).to have_current_path(new_session_path)

      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "newpassword123"
      submit_btn = find('input[type="submit"][value="Sign In"]')
      page.execute_script("arguments[0].click()", submit_btn)

      expect(page).to have_current_path(dashboard_path)
    end
  end
end
