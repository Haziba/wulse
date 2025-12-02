require 'rails_helper'

RSpec.describe "Dashboard::MetadataSuggestions", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution, password: "password123") }

  before do
    host! "#{institution.subdomain}.lvh.me"
    post session_path, params: { email: staff.email, password: "password123" }
  end

  describe "GET /dashboard/metadata_suggestions" do
    context "when there are metadata values for the key" do
      before do
        doc1 = create(:document, institution: institution, staff: staff, title: "Doc 1")
        doc2 = create(:document, institution: institution, staff: staff, title: "Doc 2")
        doc3 = create(:document, institution: institution, staff: staff, title: "Doc 3")

        create(:metadatum, document: doc1, key: "department", value: "Science")
        create(:metadatum, document: doc2, key: "department", value: "English")
        create(:metadatum, document: doc3, key: "department", value: "Science")
      end

      it "returns distinct values for the key" do
        get dashboard_metadata_suggestions_path, params: { key: "department" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        values = JSON.parse(response.body)
        expect(values).to contain_exactly("English", "Science")
      end

      it "returns values sorted alphabetically" do
        get dashboard_metadata_suggestions_path, params: { key: "department" }

        values = JSON.parse(response.body)
        expect(values).to eq(["English", "Science"])
      end
    end

    context "when there are no metadata values for the key" do
      it "returns an empty array" do
        get dashboard_metadata_suggestions_path, params: { key: "nonexistent" }

        expect(response).to have_http_status(:success)
        values = JSON.parse(response.body)
        expect(values).to eq([])
      end
    end

    context "when key is not provided" do
      it "returns an empty array" do
        get dashboard_metadata_suggestions_path

        expect(response).to have_http_status(:success)
        values = JSON.parse(response.body)
        expect(values).to eq([])
      end
    end

    context "when metadata exists in another institution" do
      let(:other_institution) { create(:institution) }
      let(:other_staff) { create(:staff, institution: other_institution) }

      before do
        other_doc = create(:document, institution: other_institution, staff: other_staff, title: "Other Doc")
        create(:metadatum, document: other_doc, key: "department", value: "Other Department")
      end

      it "only returns values from the current institution" do
        get dashboard_metadata_suggestions_path, params: { key: "department" }

        values = JSON.parse(response.body)
        expect(values).not_to include("Other Department")
      end
    end

    context "when not signed in" do
      before do
        delete session_path
      end

      it "redirects to sign in" do
        get dashboard_metadata_suggestions_path, params: { key: "department" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
