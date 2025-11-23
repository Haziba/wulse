require 'rails_helper'

RSpec.describe "Library", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /library" do
    let!(:document_1) { create(:document, institution: institution, staff: staff, title: "Introduction to Machine Learning", created_at: 1.day.ago, publishing_date: '2020-01-01') }
    let!(:document_2) { create(:document, institution: institution, staff: staff, title: "Advanced Ruby Programming", created_at: 2.days.ago, publishing_date: '2020-02-01') }
    let!(:document_3) { create(:document, institution: institution, staff: staff, title: "Data Science Fundamentals", created_at: 3.days.ago, publishing_date: '2020-03-01') }

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

    it "displays document count in filtered/total format" do
      get library_path
      expect(response.body).to include("3/3 documents found")
    end

    it "displays institution name" do
      get library_path
      expect(response.body).to include(CGI.escapeHTML(institution.name.titleize))
    end

    context "with q" do
      it "filters documents by search term" do
        get library_path(q: "Machine Learning")
        expect(response.body).to include("Introduction to Machine Learning")
        expect(response.body).not_to include("Advanced Ruby Programming")
        expect(response.body).not_to include("Data Science Fundamentals")
      end

      it "filters documents by partial search term" do
        get library_path(q: "Ruby")
        expect(response.body).to include("Advanced Ruby Programming")
        expect(response.body).not_to include("Introduction to Machine Learning")
      end

      it "returns no results when search doesn't match" do
        get library_path(q: "JavaScript")
        expect(response.body).not_to include("Introduction to Machine Learning")
        expect(response.body).not_to include("Advanced Ruby Programming")
        expect(response.body).to include("0/3 documents found")
      end

      it "displays search term in results" do
        get library_path(q: "Machine Learning")
        expect(response.body).to include("for &quot;Machine Learning&quot;")
      end

      it "displays filtered vs total count when searching" do
        get library_path(q: "Machine Learning")
        expect(response.body).to include("1/3 documents found")
      end
    end

    context "with pagination" do
      before do
        create_list(:document, 12, institution: institution, staff: staff)
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
        expect(response.body).to include('bg-brand-500')
      end
    end

    context "without authentication" do
      it "allows access to library page" do
        get library_path
        expect(response).to have_http_status(:success)
        expect(response).not_to redirect_to(new_session_path)
      end
    end

    context "with filters" do
      let!(:book1) do
        document = create(:document, institution: institution, staff: staff, title: "CS Book 2024", publishing_date: '2024-01-15')
        create(:metadatum, document: document, key: 'document_type', value: 'book')
        create(:metadatum, document: document, key: 'department', value: 'computer science')
        create(:metadatum, document: document, key: 'language', value: 'english')
        document
      end

      let!(:book2) do
        document = create(:document, institution: institution, staff: staff, title: "CS Book 2023", publishing_date: '2023-06-20')
        create(:metadatum, document: document, key: 'document_type', value: 'book')
        create(:metadatum, document: document, key: 'department', value: 'computer science')
        create(:metadatum, document: document, key: 'language', value: 'english')
        document
      end

      let!(:article1) do
        document = create(:document, institution: institution, staff: staff, title: "Economics Article", publishing_date: '2023-12-01')
        create(:metadatum, document: document, key: 'document_type', value: 'article')
        create(:metadatum, document: document, key: 'department', value: 'economics')
        create(:metadatum, document: document, key: 'language', value: 'spanish')
        document
      end

      it "displays filter sections" do
        get library_path

        expect(response.body).to include("Document type")
        expect(response.body).to include("Department")
        expect(response.body).to include("Language")
        expect(response.body).to include("Publishing date")
      end

      it "displays document type filters with counts" do
        get library_path

        expect_filter_count(response.body, "Book", 2)
        expect_filter_count(response.body, "Article", 1)
      end

      it "displays department filters with counts" do
        get library_path

        expect_filter_count(response.body, "Computer Science", 2)
        expect_filter_count(response.body, "Economics", 1)
      end

      it "displays language filters with counts" do
        get library_path

        expect_filter_count(response.body, "English", 2)
        expect_filter_count(response.body, "Spanish", 1)
      end

      it "displays publishing date filters with years" do
        get library_path

        expect_filter_count(response.body, "2023", 2)
        expect_filter_count(response.body, "2024", 1)
      end

      it "displays filtered vs total in filter counts when some filters are applied" do
        get library_path('document_type' => ['book'])

        expect_filter_count(response.body, "Book", 2)
        expect_filter_count(response.body, "Article", 0)
      end

      it "assigns @filters instance variable" do
        get library_path

        expect(assigns(:filters)).to be_a(Array)
        expect(assigns(:filters).map(&:first)).to include('document_type', 'department', 'language', :publishing_date)
      end

      it "displays checkboxes for each filter option" do
        get library_path

        checkbox_count = response.body.scan(/type="checkbox"/).count
        expect(checkbox_count).to be >= 8
      end

      it "displays filtered count vs total count when filters are applied" do
        get library_path('document_type' => ['book'])

        expect(response.body).to include("2/6 documents found")
      end

      it "displays all counts when no filters are applied" do
        get library_path

        expect(response.body).to include("6/6 documents found")
      end

      it "displays Refine Results header" do
        get library_path

        expect(response.body).to include("Refine Results")
      end

      context "with many filter values" do
        before do
          5.times do |i|
            document = create(:document, institution: institution, staff: staff, title: "Journal #{i}")
            create(:metadatum, document: document, key: 'document_type', value: 'journal')
            create(:metadatum, document: document, key: 'department', value: "department_#{i}")
          end
        end

        it "displays show all/show less toggle for filters with more than 3 items" do
          get library_path

          expect(response.body).to include('data-filter-list-target="toggle"')
        end
      end
    end
  end

  describe "GET /library/:id/read" do
    let!(:document) { create(:document, institution: institution, staff: staff, title: "Test PDF Document") }

    context "when document exists" do
      it "returns http success" do
        get library_read_path(document)
        expect(response).to have_http_status(:success)
      end

      it "displays the document title" do
        get library_read_path(document)
        expect(response.body).to include("Test PDF Document")
      end
    end

    context "when document does not exist" do
      it "returns 404 not found" do
        get library_read_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
