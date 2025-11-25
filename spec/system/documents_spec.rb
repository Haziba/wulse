require "rails_helper"

RSpec.describe "Documents", type: :system do
  before do
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  let(:institution) { create(:institution) }
  let!(:staff) { create(:staff, institution: institution, email: "admin@example.com", password: "password123") }

  def sign_in
    visit new_session_path
    fill_in "Email", with: "admin@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    expect(page).to have_current_path(dashboard_path)
  end

  describe "document list" do
    let!(:document1) { create(:document, institution: institution, staff: staff, title: "Introduction to Ruby") }
    let!(:document2) { create(:document, institution: institution, staff: staff, title: "Advanced Rails Guide") }

    before { sign_in }

    it "displays documents in the list" do
      visit dashboard_documents_path

      expect(page).to have_content("Document Management")
      expect(page).to have_content("Introduction to Ruby")
      expect(page).to have_content("Advanced Rails Guide")
    end
  end

  describe "adding a document" do
    before { sign_in }

    it "can add a new document" do
      visit dashboard_documents_path

      click_link "Add Document"

      within("dialog") do
        fill_in "Document Title", with: "New Test Document"
        fill_in "Author", with: "Test Author"
        fill_in "Publishing Date", with: "2024-01-15"
        attach_file "document[file]", Rails.root.join("spec/fixtures/files/test_document.pdf")
        click_button "Add Document"
      end

      expect(page).to have_content("New Test Document")
    end

    it "enqueues preview generation job when adding a document with file" do
      visit dashboard_documents_path

      click_link "Add Document"

      within("dialog") do
        fill_in "Document Title", with: "Document With Preview"
        fill_in "Author", with: "Preview Author"
        fill_in "Publishing Date", with: "2024-01-15"
        attach_file "document[file]", Rails.root.join("spec/fixtures/files/test_document.pdf")
      end

      expect {
        within("dialog") do
          click_button "Add Document"
        end
        expect(page).to have_content("Document With Preview")
      }.to have_enqueued_job(GeneratePreviewJob)
    end
  end

  describe "filtering documents" do
    let!(:ruby_doc) { create(:document, institution: institution, staff: staff, title: "Ruby Programming") }
    let!(:python_doc) { create(:document, institution: institution, staff: staff, title: "Python Basics") }
    let!(:rails_doc) { create(:document, institution: institution, staff: staff, title: "Rails Framework") }

    before { sign_in }

    it "filters documents by search term" do
      visit dashboard_documents_path

      fill_in "Search documents...", with: "Ruby"

      expect(page).to have_content("Ruby Programming")
      expect(page).not_to have_content("Python Basics")
      expect(page).not_to have_content("Rails Framework")
    end

    it "maintains filter in the URL" do
      visit dashboard_documents_path

      fill_in "Search documents...", with: "Python"

      # Wait for the URL to update (turbo_action: "advance")
      expect(page).to have_content("Python Basics")
      expect(page).to have_current_path(/search=Python/)
    end

    it "loads filtered documents when visiting URL with search param" do
      visit dashboard_documents_path(search: "Rails")

      expect(page).to have_content("Rails Framework")
      expect(page).not_to have_content("Ruby Programming")
      expect(page).not_to have_content("Python Basics")
      expect(find_field("Search documents...").value).to eq("Rails")
    end
  end

  describe "viewing a document" do
    let!(:document) do
      doc = create(:document, institution: institution, staff: staff, title: "Detailed Document", author: "John Smith", publishing_date: "2024-06-15")
      doc.metadata.create!(key: "department", value: "Computer Science")
      doc.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_document.pdf")),
        filename: "detailed.pdf",
        content_type: "application/pdf"
      )
      doc
    end

    before { sign_in }

    it "displays document details on the show page" do
      visit dashboard_document_path(document)

      expect(page).to have_content("Detailed Document")
      expect(page).to have_content("John Smith")
      expect(page).to have_content("2024-06-15")
      expect(page).to have_content("Computer Science")
      expect(page).to have_content("File Size:")
    end

    it "displays document metadata section" do
      visit dashboard_document_path(document)

      expect(page).to have_content("Document Metadata")
      # Metadata keys are displayed in input fields, check for the values instead
      expect(page).to have_content("Detailed Document")
      expect(page).to have_content("John Smith")
      expect(page).to have_content("2024-06-15")
      expect(page).to have_content("Computer Science")
    end
  end

  describe "editing a document" do
    let!(:document) do
      doc = create(:document, institution: institution, staff: staff, title: "Original Title", author: "Original Author")
      doc.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_document.pdf")),
        filename: "original.pdf",
        content_type: "application/pdf"
      )
      doc
    end

    before { sign_in }

    it "can edit a document's metadata" do
      visit edit_dashboard_document_path(document)

      # Find the title input and update it
      title_field = find("input[value='Original Title']")
      title_field.fill_in with: "Updated Title"

      click_button "Save Changes"

      expect(page).to have_content("Document updated successfully!")
      visit dashboard_documents_path
      expect(page).to have_content("Updated Title")
    end

    it "enqueues preview generation when uploading a new file" do
      visit edit_dashboard_document_path(document)

      attach_file "document[file]", Rails.root.join("spec/fixtures/files/test_document.pdf"), visible: false

      expect {
        click_button "Save Changes"
        expect(page).to have_content("Document updated successfully!")
      }.to have_enqueued_job(GeneratePreviewJob)
    end
  end

  describe "deleting a document" do
    let!(:document) { create(:document, institution: institution, staff: staff, title: "Document To Delete") }

    before { sign_in }

    it "can delete a document from the list" do
      visit dashboard_documents_path

      expect(page).to have_content("Document To Delete")

      within("tr", text: "Document To Delete") do
        accept_confirm do
          click_button "Delete"
        end
      end

      expect(page).not_to have_content("Document To Delete")
    end

    it "can delete a document from the edit page" do
      visit edit_dashboard_document_path(document)

      accept_confirm do
        click_link "Delete"
      end

      expect(page).to have_current_path(dashboard_documents_path)
      expect(page).not_to have_content("Document To Delete")
    end
  end
end
