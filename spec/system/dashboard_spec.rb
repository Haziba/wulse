require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  before do
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution, branding_colour: "#1e40af", storage_total: 10.gigabytes) }
  let!(:staff) { create(:staff, institution: institution, email: "admin@example.com", password: "password123") }

  let!(:other_staff) { create(:staff, institution: institution, name: "Jane Doe") }

  let!(:document1) do
    doc = create(:document, institution: institution, staff: staff, title: "First Document", created_at: 1.day.ago)
    doc.file.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/large.pdf")),
      filename: "doc1.pdf",
      content_type: "application/pdf"
    )
    doc
  end

  let!(:document2) do
    create(:document, institution: institution, staff: other_staff, title: "Second Document", created_at: 2.days.ago)
  end

  before do
    visit new_session_path
    fill_in "Email", with: "admin@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    expect(page).to have_current_path(dashboard_path)
  end

  describe "stats cards" do
    it "displays total documents count" do
      expect(page).to have_content("Total Documents")
      expect(page).to have_content("2")
    end

    it "displays active staff count" do
      expect(page).to have_content("Active Staff")
      expect(page).to have_content("2")
    end

    it "displays storage usage" do
      expect(page).to have_content("Storage Used")
      expect(page).to have_content("6.45 KB")
      expect(page).to have_content("of 10 GB")
    end
  end

  describe "recent documents" do
    it "displays recent documents section" do
      expect(page).to have_content("Recent Documents")
      expect(page).to have_content("First Document")
      expect(page).to have_content("Second Document")
    end

    it "links document to view page" do
      click_link "First Document"
      expect(page).to have_current_path(dashboard_document_path(document1))
    end

    it "has View All link to documents index" do
      within(".lg\\:col-span-2") do
        click_link "View All"
      end
      expect(page).to have_current_path(dashboard_documents_path)
    end
  end

  describe "staff overview" do
    it "displays staff overview section" do
      expect(page).to have_content("Staff Overview")
      expect(page).to have_content("Jane Doe")
    end

    it "links staff to view page" do
      staff_section = find("h3", text: "Staff Overview").ancestor(".bg-white")
      within(staff_section) do
        click_link "Jane Doe"
      end
      expect(page).to have_current_path(dashboard_staff_path(other_staff))
    end

    it "has View All link to staff index" do
      staff_section = find("h3", text: "Staff Overview").ancestor(".bg-white")
      within(staff_section) do
        click_link "View All"
      end
      expect(page).to have_current_path(dashboard_staff_index_path)
    end
  end

  describe "stats card links" do
    it "Total Documents card links to documents index" do
      click_link "Total Documents"
      expect(page).to have_current_path(dashboard_documents_path)
    end

    it "Active Staff card links to staff index" do
      click_link "Active Staff"
      expect(page).to have_current_path(dashboard_staff_index_path)
    end
  end
end
