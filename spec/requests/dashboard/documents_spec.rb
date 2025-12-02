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
      let!(:document_1) { create(:document, institution: institution, staff: staff, title: "Introduction to Ruby", updated_at: 1.hour.ago) }
      let!(:document_2) { create(:document, institution: institution, staff: staff, title: "Advanced Rails", updated_at: 2.days.ago) }
      let!(:other_institution_document) { create(:document, institution: other_institution, title: "Python Basics") }

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

      it "highlights documents link in the header" do
        get dashboard_documents_path
        expect(response.body).to include('href="' + dashboard_documents_path + '"', "Documents", "text-brand-500 border-b-2 border-brand-500")
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
          create_list(:document, 3, institution: institution, staff: staff)
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
            document: {
              metadata_attributes: {
                "0" => { key: "title", value: "Test Document" },
                "1" => { key: "author", value: "Test Author" },
                "2" => { key: "publishing_date", value: "2024-01-01" }
              },
              file: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }
        end

        it "creates a new document" do
          expect {
            post dashboard_documents_path, params: valid_params
          }.to change(Document, :count).by(1)
        end

        it "associates document with current staff" do
          post dashboard_documents_path, params: valid_params
          expect(Document.last.staff).to eq(staff)
        end

        it "responds with turbo stream that updates the document list" do
          post dashboard_documents_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("Test Document")
          expect(response.body).to include('turbo-stream action="update" target="document_list"')
        end

        it "redirects on html request" do
          post dashboard_documents_path, params: valid_params
          expect(response).to redirect_to(dashboard_documents_path)
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            document: {
              metadata_attributes: { "0" => { key: "title", value: "" } }
            }
          }
        end

        it "does not create a new document" do
          expect {
            post dashboard_documents_path, params: invalid_params
          }.not_to change(Document, :count)
        end

        it "renders the form again" do
          post dashboard_documents_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when institution is in demo mode" do
        let(:demo_institution) { create(:institution, demo: true) }
        let(:demo_staff) { create(:staff, institution: demo_institution) }

        before do
          host! "#{demo_institution.subdomain}.lvh.me"
          post session_path, params: {
            email: demo_staff.email,
            password: demo_staff.password
          }
        end

        let(:valid_params) do
          {
            document: {
              metadata_attributes: {
                "0" => { key: "title", value: "Test Document" },
                "1" => { key: "author", value: "Test Author" },
                "2" => { key: "publishing_date", value: "2024-01-01" }
              },
              file: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }
        end

        it "does not create a new document" do
          expect {
            post dashboard_documents_path, params: valid_params
          }.not_to change(Document, :count)
        end

        it "returns a turbo stream with an alert toast" do
          post dashboard_documents_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Changes not allowed in Demo mode")
        end

        it "redirects with alert on html request" do
          post dashboard_documents_path, params: valid_params
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:alert]).to eq("Changes not allowed in Demo mode.")
        end
      end
    end
  end

  describe "GET /dashboard/documents/:id" do
    let!(:document) { create(:document, institution: institution, staff: staff, title: "Test Document") }
    let!(:other_institution_document) { create(:document, institution: other_institution) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        get dashboard_document_path(document)
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
        get dashboard_document_path(document)
        expect(response).to have_http_status(:success)
      end

      it "highlights documents link in the header" do
        get dashboard_document_path(document)
        expect(response.body).to include('href="' + dashboard_documents_path + '"', "Documents", "text-brand-500 border-b-2 border-brand-500")
      end

      it "displays the document" do
        get dashboard_document_path(document)
        expect(response.body).to include("Test Document")
      end

      it "cannot view other institution's documents" do
        get dashboard_document_path(other_institution_document)
        expect(response).to redirect_to(dashboard_documents_path)
      end
    end
  end

  describe "GET /dashboard/documents/:id/edit" do
    let!(:document) { create(:document, institution: institution, staff: staff, title: "Test Document") }
    let!(:other_institution_document) { create(:document, institution: other_institution) }

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

      it "highlights documents link in the header" do
        get edit_dashboard_document_path(document)
        expect(response.body).to include('href="' + dashboard_documents_path + '"', "Documents", "text-brand-500 border-b-2 border-brand-500")
      end

      it "assigns the document" do
        get edit_dashboard_document_path(document)
        expect(assigns(:document)).to eq(document)
      end

      it "loads document with metadata" do
        create(:metadatum, document: document, key: 'isbn', value: '123-456')
        create(:metadatum, document: document, key: 'year', value: '2024')

        get edit_dashboard_document_path(document)

        expect(assigns(:document).metadata.loaded?).to be true
        expect(assigns(:document).metadata.count).to eq(5) # 5 because factory creates title, author, publishing_date + 2 above
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
        expect(response).to redirect_to(dashboard_documents_path)
      end

      context "required metadata" do
        it "always includes required metadata fields even when none exist" do
          get edit_dashboard_document_path(document)

          metadata = assigns(:metadata)
          metadata_keys = metadata.map(&:key)

          expect(metadata_keys).to include('author')
          expect(metadata_keys).to include('title')
          expect(metadata_keys).to include('publishing_date')
        end

        it "shows required metadata first in order" do
          create(:metadatum, document: document, key: 'publisher', value: 'O\'Reilly')
          create(:metadatum, document: document, key: 'year', value: '2024')

          get edit_dashboard_document_path(document)

          metadata = assigns(:metadata)
          metadata_keys = metadata.map(&:key)

          # Required metadata should appear first (factory creates these, order matches REQUIRED_METADATA)
          expect(metadata_keys[0..2]).to eq([ 'title', 'author', 'publishing_date' ])
          # Custom metadata should appear after
          expect(metadata_keys[3..4]).to match_array([ 'publisher', 'year' ])
        end

        it "uses existing required metadata when they exist" do
          # Factory already creates author, so we just verify it exists
          get edit_dashboard_document_path(document)

          metadata = assigns(:metadata)
          author_metadata = metadata.find { |m| m.key == 'author' }

          expect(author_metadata).not_to be_nil
          expect(author_metadata.new_record?).to be false
        end
      end
    end
  end

  describe "PATCH /dashboard/documents/:id" do
    let!(:document) { create(:document, institution: institution, staff: staff, title: "Original Name") }
    let!(:other_institution_document) { create(:document, institution: other_institution) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        patch dashboard_document_path(document), params: { document: { metadata_attributes: { "0" => { key: "title", value: "New Name" } } } }
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
            document: {
              metadata_attributes: {
                "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: "Updated Document Name" }
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
            document: {
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
        let!(:existing_metadata) { create(:metadatum, document: document, key: 'isbn', value: '123-456') }

        it "creates new metadata" do
          params = {
            document: {
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
            document: {
              metadata_attributes: {
                "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title },
                "1" => { id: existing_metadata.id, key: "isbn", value: "999-999" }
              }
            }
          }

          patch dashboard_document_path(document), params: params
          expect(existing_metadata.reload.value).to eq("999-999")
        end

        it "deletes metadata when _destroy is set" do
          params = {
            document: {
              metadata_attributes: { "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title }, "1" => { id: existing_metadata.id, key: "isbn", value: "123-456", _destroy: "1" } }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.to change { document.metadata.count }.by(-1)
        end

        it "deletes existing metadata when value is set to blank" do
          params = {
            document: {
              metadata_attributes: {
                "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title },
                "1" => { id: existing_metadata.id, key: "isbn", value: "" }
              }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.to change { document.metadata.count }.by(-1)

          expect(document.metadata.find_by(key: 'isbn')).to be_nil
        end

        it "does not create new metadata with blank value" do
          params = {
            document: {
              metadata_attributes: {
                "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title },
                "1" => { key: "publisher", value: "" }
              }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.not_to change { document.metadata.count }

          expect(document.metadata.find_by(key: 'publisher')).to be_nil
        end
        it "updates the document file" do
          params = {
            document: {
              metadata_attributes: { "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title } },
              file: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }

          patch dashboard_document_path(document), params: params
          expect(document.reload.file).to be_attached
        end

        it "updates the preview image" do
          params = {
            document: {
              metadata_attributes: { "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title } },
              preview_image: fixture_file_upload('avatar.jpg', 'image/jpeg')
            }
          }

          patch dashboard_document_path(document), params: params
          expect(document.reload.preview_image).to be_attached
        end

        it "enqueues GeneratePreviewJob when a new document is uploaded" do
          params = {
            document: {
              metadata_attributes: { "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title } },
              file: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.to have_enqueued_job(GeneratePreviewJob)

          # Verify job is enqueued with correct parameters
          expect(GeneratePreviewJob).to have_been_enqueued.with(
            'Document',
            document.id,
            document.reload.file.blob.key
          )
        end

        it "does not enqueue GeneratePreviewJob when no document is provided" do
          params = {
            document: {
              metadata_attributes: { "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: "Updated Name Only" } }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.not_to have_enqueued_job(GeneratePreviewJob)
        end

        it "does not enqueue GeneratePreviewJob when document upload fails" do
          allow_any_instance_of(Document).to receive(:update).and_return(false)

          params = {
            document: {
              metadata_attributes: { "0" => { id: document.metadata.find_by(key: 'title').id, key: "title", value: document.title } },
              file: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.not_to have_enqueued_job(GeneratePreviewJob)
        end
      end

      context "multi-tenancy" do
        it "cannot update other institution's documents" do
          patch dashboard_document_path(other_institution_document), params: { document: { metadata_attributes: { "0" => { key: "title", value: "Hacked" } } } }
          expect(response).to redirect_to(dashboard_documents_path)
        end
      end

      context "when institution is in demo mode" do
        let(:demo_institution) { create(:institution, demo: true) }
        let(:demo_staff) { create(:staff, institution: demo_institution) }
        let!(:demo_document) { create(:document, institution: demo_institution, staff: demo_staff, title: "Demo Document") }

        before do
          host! "#{demo_institution.subdomain}.lvh.me"
          post session_path, params: {
            email: demo_staff.email,
            password: demo_staff.password
          }
        end

        it "does not update the document" do
          original_title = demo_document.title
          patch dashboard_document_path(demo_document), params: {
            document: { metadata_attributes: { "0" => { id: demo_document.metadata.find_by(key: 'title').id, key: "title", value: "New Title" } } }
          }
          expect(demo_document.reload.title).to eq(original_title)
        end

        it "returns an alert" do
          patch dashboard_document_path(demo_document), params: {
            document: { metadata_attributes: { "0" => { id: demo_document.metadata.find_by(key: 'title').id, key: "title", value: "New Title" } } }
          }
          expect(flash[:alert]).to eq("Changes not allowed in Demo mode.")
        end
      end
    end
  end

  describe "DELETE /dashboard/documents/:id" do
    let!(:document) { create(:document, institution: institution, staff: staff, title: "Test Document") }

    context "when authenticated" do
      before do
        post session_path, params: {
          email: staff.email,
          password: staff.password
        }
      end

      it "deletes the document" do
        expect {
          delete dashboard_document_path(document)
        }.to change(Document, :count).by(-1)
      end

      it "responds with turbo stream that updates the document list" do
        delete dashboard_document_path(document), headers: { "Accept" => "text/vnd.turbo-stream.html", "Turbo-Frame" => "document_list" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).not_to include("Test Document")
        expect(response.body).to include('turbo-stream action="update" target="document_list"')
      end

      it "redirects on html request" do
        delete dashboard_document_path(document)
        expect(response).to redirect_to(dashboard_documents_path)
      end

      context "when institution is in demo mode" do
        let(:demo_institution) { create(:institution, demo: true) }
        let(:demo_staff) { create(:staff, institution: demo_institution) }
        let!(:demo_document) { create(:document, institution: demo_institution, staff: demo_staff, title: "Demo Document") }

        before do
          host! "#{demo_institution.subdomain}.lvh.me"
          post session_path, params: {
            email: demo_staff.email,
            password: demo_staff.password
          }
        end

        it "does not delete the document" do
          expect {
            delete dashboard_document_path(demo_document)
          }.not_to change(Document, :count)
        end

        it "returns an alert" do
          delete dashboard_document_path(demo_document)
          expect(flash[:alert]).to eq("Changes not allowed in Demo mode.")
        end
      end
    end
  end
end
