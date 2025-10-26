require 'rails_helper'

RSpec.describe "Dashboard::Documents", type: :request do
  let(:institution) { create(:institution) }
  let(:other_institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /dashboard/documents" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get dashboard_documents_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      let!(:document_1) { create(:oer, institution: institution, staff: staff, title: "Introduction to Ruby", updated_at: 1.hour.ago) }
      let!(:document_2) { create(:oer, institution: institution, staff: staff, title: "Advanced Rails", updated_at: 2.days.ago) }
      let!(:other_institution_document) { create(:oer, institution: other_institution, title: "Python Basics") }

      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "returns http success" do
        get dashboard_documents_path
        expect(response).to have_http_status(:success)
      end

      it "displays only documents from the current institution" do
        get dashboard_documents_path
        expect(response.body).to include("Introduction to Ruby")
        expect(response.body).to include("Advanced Rails")
        expect(response.body).not_to include("Python Basics")
      end

      it "displays document author" do
        get dashboard_documents_path
        expect(response.body).to include(CGI.escapeHTML(staff.name))
      end

      it "displays last updated times" do
        get dashboard_documents_path
        expect(response.body).to match(/\d+\s+(hour|hours)\s+ago/)
        expect(response.body).to match(/\d+\s+(day|days)\s+ago/)
      end

      context "with pagination" do
        before do
          stub_const("Pagy::DEFAULT", Pagy::DEFAULT.merge(limit: 2))
          create_list(:oer, 3, institution: institution, staff: staff)
        end

        it "paginates documents" do
          get dashboard_documents_path
          expect(response.body).to include("Showing 1 to 2 of")
        end

        it "displays correct documents on page 1" do
          get dashboard_documents_path(page: 1)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Showing 1 to 2 of")
        end

        it "displays correct documents on page 2" do
          get dashboard_documents_path(page: 2)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Showing 3 to")
        end

        it "includes pagination controls" do
          get dashboard_documents_path
          expect(response.body).to include("Previous")
          expect(response.body).to include("Next")
        end
      end

      context "with filtering" do
        it "filters documents by search term" do
          get dashboard_documents_path(search: "Ruby")
          expect(response.body).to include("Introduction to Ruby")
          expect(response.body).not_to include("Advanced Rails")
        end

        it "filters documents by partial search term" do
          get dashboard_documents_path(search: "Rails")
          expect(response.body).to include("Advanced Rails")
          expect(response.body).not_to include("Introduction to Ruby")
        end

        it "returns no results when search doesn't match" do
          get dashboard_documents_path(search: "JavaScript")
          expect(response.body).not_to include("Introduction to Ruby")
          expect(response.body).not_to include("Advanced Rails")
        end
      end
    end
  end

  describe "POST /dashboard/documents" do
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
            oer: {
              metadata_attributes: { "0" => { key: "title", value: "Test Document" } },
              document: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }
        end

        it "creates a new document" do
          expect {
            post dashboard_documents_path, params: valid_params
          }.to change(Oer, :count).by(1)
        end

        it "associates document with current staff" do
          post dashboard_documents_path, params: valid_params
          expect(Oer.last.staff).to eq(staff)
        end

        it "responds with turbo stream that updates the document list" do
          post dashboard_documents_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("Test Document")
          expect(response.body).to include('turbo-stream action="replace" target="document_list"')
        end

        it "redirects on html request" do
          post dashboard_documents_path, params: valid_params
          expect(response).to redirect_to(dashboard_documents_path)
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: "" } }
            }
          }
        end

        it "does not create a new document" do
          expect {
            post dashboard_documents_path, params: invalid_params
          }.not_to change(Oer, :count)
        end

        it "renders the form again" do
          post dashboard_documents_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "GET /dashboard/documents/:id/edit" do
    let!(:document) { create(:oer, institution: institution, staff: staff, title: "Test Document") }
    let!(:other_institution_document) { create(:oer, institution: other_institution) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        get edit_dashboard_document_path(document)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "returns http success" do
        get edit_dashboard_document_path(document)
        expect(response).to have_http_status(:success)
      end

      it "assigns the document" do
        get edit_dashboard_document_path(document)
        expect(assigns(:document)).to eq(document)
      end

      it "loads document with metadata" do
        create(:metadatum, oer: document, key: 'author', value: 'John Doe')
        create(:metadatum, oer: document, key: 'year', value: '2024')

        get edit_dashboard_document_path(document)

        expect(assigns(:document).metadata.loaded?).to be true
        expect(assigns(:document).metadata.count).to eq(2)
      end

      it "displays file upload UI" do
        get edit_dashboard_document_path(document)

        expect(response.body).to include('Upload file')
        expect(response.body).to include('id="document-file-input"')
        expect(response.body).to include('type="file"')
      end

      it "displays file upload with correct accept attribute" do
        get edit_dashboard_document_path(document)

        expect(response.body).to include('accept="application/pdf,application/epub+zip"')
      end

      it "displays upload icon in overlay" do
        get edit_dashboard_document_path(document)

        expect(response.body).to include('fa-upload')
      end

      it "cannot edit other institution's documents" do
        get edit_dashboard_document_path(other_institution_document)
        expect(response).to have_http_status(:not_found)
      end

      context "required metadata" do
        it "always includes required metadata fields even when none exist" do
          get edit_dashboard_document_path(document)

          metadata = assigns(:metadata)
          metadata_keys = metadata.map(&:key)

          expect(metadata_keys).to include('isbn')
          expect(metadata_keys).to include('author')
          expect(metadata_keys).to include('title')
        end

        it "shows required metadata first in order" do
          create(:metadatum, oer: document, key: 'publisher', value: 'O\'Reilly')
          create(:metadatum, oer: document, key: 'year', value: '2024')

          get edit_dashboard_document_path(document)

          metadata = assigns(:metadata)
          metadata_keys = metadata.map(&:key)

          # Required metadata should appear first
          expect(metadata_keys[0..2]).to eq(['isbn', 'author', 'title'])
          # Custom metadata should appear after
          expect(metadata_keys[3..4]).to match_array(['publisher', 'year'])
        end

        it "initializes required metadata as new records when they don't exist" do
          get edit_dashboard_document_path(document)

          metadata = assigns(:metadata)
          isbn_metadata = metadata.find { |m| m.key == 'isbn' }
          author_metadata = metadata.find { |m| m.key == 'author' }
          title_metadata = metadata.find { |m| m.key == 'title' }

          expect(isbn_metadata).to be_present
          expect(isbn_metadata.new_record?).to be true
          expect(author_metadata).to be_present
          expect(author_metadata.new_record?).to be true
          expect(title_metadata).to be_present
          expect(title_metadata.new_record?).to be true
        end

        it "uses existing required metadata when they exist" do
          existing_author = create(:metadatum, oer: document, key: 'author', value: 'Jane Doe')

          get edit_dashboard_document_path(document)

          metadata = assigns(:metadata)
          author_metadata = metadata.find { |m| m.key == 'author' }

          expect(author_metadata).to eq(existing_author)
          expect(author_metadata.new_record?).to be false
          expect(author_metadata.value).to eq('Jane Doe')
        end
      end
    end
  end

  describe "PATCH /dashboard/documents/:id" do
    let!(:document) { create(:oer, institution: institution, staff: staff, title: "Original Name") }
    let!(:other_institution_document) { create(:oer, institution: other_institution) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        patch dashboard_document_path(document), params: { oer: { metadata_attributes: { "0" => { key: "title", value: "New Name" } } } }
        expect(response).to redirect_to(new_session_path)
      end
    end

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
            oer: {
              metadata_attributes: {
                "0" => { key: "title", value: "Updated Document Name" }
              }
            }
          }
        end

        it "updates the document" do
          patch dashboard_document_path(document), params: valid_params
          expect(document.reload.title).to eq("Updated Document Name")
        end

        it "redirects to documents index" do
          patch dashboard_document_path(document), params: valid_params
          expect(response).to redirect_to(dashboard_documents_path)
        end

        it "sets a success notice" do
          patch dashboard_document_path(document), params: valid_params
          expect(flash[:notice]).to eq("Document updated successfully!")
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: "" } }
            }
          }
        end

        it "does not update the document" do
          original_name = document.title
          patch dashboard_document_path(document), params: invalid_params
          expect(document.reload.title).to eq(original_name)
        end

        it "renders the edit template" do
          patch dashboard_document_path(document), params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "updating metadata" do
        let!(:existing_metadata) { create(:metadatum, oer: document, key: 'author', value: 'John Doe') }

        it "creates new metadata" do
          params = {
            oer: {
              metadata_attributes: {
                "0" => { key: "year", value: "2024" }
              }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.to change { document.metadata.count }.by(1)

          expect(document.metadata.find_by(key: 'year').value).to eq('2024')
        end

        it "updates existing metadata" do
          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: document.title }, "1" => { key: "author", value: "Jane Smith" } }
            }
          }

          patch dashboard_document_path(document), params: params
          expect(existing_metadata.reload.value).to eq("Jane Smith")
        end

        it "deletes metadata when _destroy is set" do
          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: document.title }, "1" => { key: "author", value: "John Doe", _destroy: "1" } }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.to change { document.metadata.count }.by(-1)
        end

        it "rejects blank metadata" do
          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: document.title }, "1" => { key: "author", value: "" } }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.not_to change { document.metadata.count }
        end
        it "updates the document file" do
          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: document.title } },
              document: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }

          patch dashboard_document_path(document), params: params
          expect(document.reload.document).to be_attached
        end

        it "updates the preview image" do
          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: document.title } },
              preview_image: fixture_file_upload('avatar.jpg', 'image/jpeg')
            }
          }

          patch dashboard_document_path(document), params: params
          expect(document.reload.preview_image).to be_attached
        end

        it "enqueues GeneratePreviewJob when a new document is uploaded" do
          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: document.title } },
              document: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.to have_enqueued_job(GeneratePreviewJob)

          # Verify job is enqueued with correct parameters
          expect(GeneratePreviewJob).to have_been_enqueued.with(
            'Oer',
            document.id,
            document.reload.document.blob.key
          )
        end

        it "does not enqueue GeneratePreviewJob when no document is provided" do
          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: "Updated Name Only" } }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.not_to have_enqueued_job(GeneratePreviewJob)
        end

        it "does not enqueue GeneratePreviewJob when document upload fails" do
          allow_any_instance_of(Oer).to receive(:update).and_return(false)

          params = {
            oer: {
              metadata_attributes: { "0" => { key: "title", value: document.title } },
              document: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.not_to have_enqueued_job(GeneratePreviewJob)
        end
      end

      context "multi-tenancy" do
        it "cannot update other institution's documents" do
          patch dashboard_document_path(other_institution_document), params: { oer: { metadata_attributes: { "0" => { key: "title", value: "Hacked" } } } }
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
