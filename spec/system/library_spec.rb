require "rails_helper"

RSpec.describe "Library", type: :system do
  before do
    driven_by(:selenium_headless)
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution, branding_colour: "#1e40af") }
  let(:staff) { create(:staff, institution: institution) }

  let!(:ruby_book) do
    create(:document,
      institution: institution,
      staff: staff,
      title: "Introduction to Ruby Programming",
      author: "Matz Yukihiro"
    )
  end

  describe "searching and reading a book" do
    let!(:js_book) do
      create(:document,
        institution: institution,
        staff: staff,
        title: "JavaScript Fundamentals",
        author: "Brendan Eich"
      )
    end

    it "allows an anonymous user to search for a book and read it" do
      visit library_path

      expect(page).to have_content("Introduction to Ruby Programming")
      expect(page).to have_content("JavaScript Fundamentals")

      fill_in "q", with: "Ruby"
      find('button[aria-label="Search"]', match: :first).click

      expect(page).to have_content("Introduction to Ruby Programming")
      expect(page).to have_content("Matz Yukihiro")
      expect(page).not_to have_content("JavaScript Fundamentals")

      find('a[aria-label="Read Introduction to Ruby Programming"]').click

      expect(page).to have_css("#reader-interface")
      expect(page).to have_content("Introduction to Ruby Programming")
      expect(page).to have_content("Matz Yukihiro")
      expect(page).to have_content("Table of Contents")
    end
  end

  describe "downloading a book" do
    before do
      ruby_book.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_document.pdf")),
        filename: "test_document.pdf",
        content_type: "application/pdf"
      )
    end

    it "allows an anonymous user to download a book" do
      visit library_path

      download_link = find('a[aria-label="Download Introduction to Ruby Programming"]')
      expect(download_link[:href]).to include("test_document.pdf")
      expect(download_link[:href]).to include("disposition=attachment")
    end
  end
end
