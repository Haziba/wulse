require "rails_helper"
require "axe-rspec"

RSpec.describe "Accessibility", type: :system do
  before do
    driven_by(:selenium_headless)
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution, branding_colour: "#1e40af") }

  describe "Library pages" do
    it "library index page is accessible" do
      create_list(:document, 3, institution: institution)

      visit library_path

      expect(page).to be_axe_clean
    end
  end

  describe "Dashboard pages" do
    let(:staff) { create(:staff, institution: institution, password: "password123") }

    it "dashboard index page is accessible" do
      sign_in_as(staff)

      visit dashboard_path

      expect(page).to be_axe_clean
    end

    it "documents index page is accessible" do
      create_list(:document, 3, institution: institution, staff: staff)
      sign_in_as(staff)

      visit dashboard_documents_path

      expect(page).to be_axe_clean
    end

    it "staff index page is accessible" do
      create_list(:staff, 3, institution: institution)
      sign_in_as(staff)

      visit dashboard_staff_index_path

      expect(page).to be_axe_clean
    end
  end

  private

  def sign_in_as(staff)
    visit new_session_path
    fill_in "Email", with: staff.email
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end
end
