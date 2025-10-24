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
      let!(:document_1) { create(:oer, institution: institution, staff: staff, name: "Introduction to Ruby", updated_at: 1.hour.ago) }
      let!(:document_2) { create(:oer, institution: institution, staff: staff, name: "Advanced Rails", updated_at: 2.days.ago) }
      let!(:other_institution_document) { create(:oer, institution: other_institution, name: "Python Basics") }

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
              name: "Test Document",
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
              name: ""
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
    let!(:document) { create(:oer, institution: institution, staff: staff, name: "Test Document") }
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

      it "cannot edit other institution's documents" do
        get edit_dashboard_document_path(other_institution_document)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /dashboard/documents/:id" do
    let!(:document) { create(:oer, institution: institution, staff: staff, name: "Original Name") }
    let!(:other_institution_document) { create(:oer, institution: other_institution) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        patch dashboard_document_path(document), params: { oer: { name: "New Name" } }
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
              name: "Updated Document Name"
            }
          }
        end

        it "updates the document" do
          patch dashboard_document_path(document), params: valid_params
          expect(document.reload.name).to eq("Updated Document Name")
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
              name: ""
            }
          }
        end

        it "does not update the document" do
          original_name = document.name
          patch dashboard_document_path(document), params: invalid_params
          expect(document.reload.name).to eq(original_name)
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
              name: document.name,
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
              name: document.name,
              metadata_attributes: {
                "0" => { id: existing_metadata.id, key: "author", value: "Jane Smith" }
              }
            }
          }

          patch dashboard_document_path(document), params: params
          expect(existing_metadata.reload.value).to eq("Jane Smith")
        end

        it "deletes metadata when _destroy is set" do
          params = {
            oer: {
              name: document.name,
              metadata_attributes: {
                "0" => { id: existing_metadata.id, key: "author", value: "John Doe", _destroy: "1" }
              }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.to change { document.metadata.count }.by(-1)
        end

        it "rejects blank metadata" do
          params = {
            oer: {
              name: document.name,
              metadata_attributes: {
                "0" => { key: "", value: "" }
              }
            }
          }

          expect {
            patch dashboard_document_path(document), params: params
          }.not_to change { document.metadata.count }
        end
      end

      context "uploading files" do
        it "updates the document file" do
          params = {
            oer: {
              name: document.name,
              document: fixture_file_upload('test_document.pdf', 'application/pdf')
            }
          }

          patch dashboard_document_path(document), params: params
          expect(document.reload.document).to be_attached
        end

        it "updates the preview image" do
          params = {
            oer: {
              name: document.name,
              preview_image: fixture_file_upload('avatar.jpg', 'image/jpeg')
            }
          }

          patch dashboard_document_path(document), params: params
          expect(document.reload.preview_image).to be_attached
        end
      end

      context "multi-tenancy" do
        it "cannot update other institution's documents" do
          patch dashboard_document_path(other_institution_document), params: { oer: { name: "Hacked" } }
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
