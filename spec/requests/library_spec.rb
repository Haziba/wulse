require 'rails_helper'

RSpec.describe "Library", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /library" do
    let!(:document_1) { create(:oer, institution: institution, staff: staff, name: "Introduction to Machine Learning", created_at: 1.day.ago) }
    let!(:document_2) { create(:oer, institution: institution, staff: staff, name: "Advanced Ruby Programming", created_at: 2.days.ago) }
    let!(:document_3) { create(:oer, institution: institution, staff: staff, name: "Data Science Fundamentals", created_at: 3.days.ago) }

    it "returns http success" do
      get library_path
      expect(response).to have_http_status(:success)
    end

    it "displays all documents" do
      get library_path
      expect(response.body).to include("Introduction to Machine Learning")
      expect(response.body).to include("Advanced Ruby Programming")
      expect(response.body).to include("Data Science Fundamentals")
    end

    it "displays document count" do
      get library_path
      expect(response.body).to include("3 documents found")
    end

    it "displays institution name" do
      get library_path
      expect(response.body).to include(institution.name.titleize)
    end

    context "with search" do
      it "filters documents by search term" do
        get library_path(search: "Machine Learning")
        expect(response.body).to include("Introduction to Machine Learning")
        expect(response.body).not_to include("Advanced Ruby Programming")
        expect(response.body).not_to include("Data Science Fundamentals")
      end

      it "filters documents by partial search term" do
        get library_path(search: "Ruby")
        expect(response.body).to include("Advanced Ruby Programming")
        expect(response.body).not_to include("Introduction to Machine Learning")
      end

      it "returns no results when search doesn't match" do
        get library_path(search: "JavaScript")
        expect(response.body).not_to include("Introduction to Machine Learning")
        expect(response.body).not_to include("Advanced Ruby Programming")
        expect(response.body).to include("0 documents found")
      end

      it "displays search term in results" do
        get library_path(search: "Machine Learning")
        expect(response.body).to include("for &quot;Machine Learning&quot;")
      end
    end

    context "with pagination" do
      before do
        create_list(:oer, 12, institution: institution, staff: staff)
      end

      it "paginates documents" do
        get library_path
        expect(response.body).to include("Showing 1 to 10 of")
      end

      it "displays correct documents on page 1" do
        get library_path(page: 1)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Showing 1 to 10 of")
      end

      it "displays correct documents on page 2" do
        get library_path(page: 2)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Showing 11 to")
      end

      it "includes pagination controls" do
        get library_path
        expect(response.body).to include("chevron-left")
        expect(response.body).to include("chevron-right")
      end

      it "shows active page highlight" do
        get library_path(page: 2)
        expect(response.body).to include('bg-burgundy-500')
      end
    end

    context "without authentication" do
      it "allows access to library page" do
        get library_path
        expect(response).to have_http_status(:success)
        expect(response).not_to redirect_to(new_session_path)
      end
    end
  end
end
