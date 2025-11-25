require "rails_helper"

RSpec.describe "Home", type: :system do
  before do
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution, branding_colour: "#1e40af") }
  let(:staff) { create(:staff, institution: institution) }

  let!(:recent_book) do
    doc = create(:document,
      institution: institution,
      staff: staff,
      title: "Recent Research Paper",
      author: "Dr. Smith"
    )
    doc.file.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/large.pdf")),
      filename: "research.pdf",
      content_type: "application/pdf"
    )
    doc
  end

  describe "homepage" do
    it "displays recently added documents" do
      visit root_path

      expect(page).to have_content("Recently Added")
      expect(page).to have_content("Recent Research Paper")
      expect(page).to have_content("Dr. Smith")
    end

    it "links to read a document" do
      visit root_path

      find('a[aria-label="Read Recent Research Paper"]').click

      expect(page).to have_css("#reader-interface")
      expect(page).to have_content("Recent Research Paper")
    end

    it "links to download a document" do
      visit root_path

      download_link = find('a[aria-label="Download Recent Research Paper"]')
      expect(download_link[:href]).to include("research.pdf")
      expect(download_link[:href]).to include("disposition=attachment")
    end

    it "searches and navigates to library index" do
      visit root_path

      within('form[action="/library"]') do
        fill_in "q", with: "Machine Learning"
      end

      find('form[action="/library"] button[type="submit"]').click

      expect(page).to have_content("Search Results", wait: 5)
      expect(current_path).to eq(library_path)
      expect(current_url).to include("q=Machine")
    end
  end
end
