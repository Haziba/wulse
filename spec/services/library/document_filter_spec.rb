require 'rails_helper'

RSpec.describe Library::DocumentFilter do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  describe ".call" do
    context "with no filters" do
      it "returns all documents" do
        doc1 = create(:oer, institution: institution, staff: staff, title: "Doc 1")
        doc2 = create(:oer, institution: institution, staff: staff, title: "Doc 2")

        result = described_class.call({})

        expect(result).to include(doc1, doc2)
      end
    end

    context "with search filter" do
      let!(:ruby_doc) do
        create(:oer, institution: institution, staff: staff, title: "Ruby Programming")
      end

      let!(:python_doc) do
        create(:oer, institution: institution, staff: staff, title: "Python Basics")
      end

      it "filters by search term in title" do
        result = described_class.call(search: "Ruby")

        expect(result).to include(ruby_doc)
        expect(result).not_to include(python_doc)
      end

      it "performs case-insensitive search" do
        result = described_class.call(search: "ruby")

        expect(result).to include(ruby_doc)
      end

      it "performs partial match search" do
        result = described_class.call(search: "Program")

        expect(result).to include(ruby_doc)
      end

      it "returns no results for non-matching search" do
        result = described_class.call(search: "JavaScript")

        expect(result).to be_empty
      end
    end

    context "with document_type filter" do
      let!(:book) do
        oer = create(:oer, institution: institution, staff: staff, title: "Book")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        oer
      end

      let!(:article) do
        oer = create(:oer, institution: institution, staff: staff, title: "Article")
        create(:metadatum, oer: oer, key: 'document_type', value: 'article')
        oer
      end

      it "filters by single document type" do
        result = described_class.call('document_type' => ['book'])

        expect(result).to include(book)
        expect(result).not_to include(article)
      end

      it "filters by multiple document types" do
        result = described_class.call('document_type' => ['book', 'article'])

        expect(result).to include(book, article)
      end
    end

    context "with department filter" do
      let!(:cs_doc) do
        oer = create(:oer, institution: institution, staff: staff, title: "CS Doc")
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')
        oer
      end

      let!(:econ_doc) do
        oer = create(:oer, institution: institution, staff: staff, title: "Econ Doc")
        create(:metadatum, oer: oer, key: 'department', value: 'economics')
        oer
      end

      it "filters by department" do
        result = described_class.call('department' => ['computer science'])

        expect(result).to include(cs_doc)
        expect(result).not_to include(econ_doc)
      end
    end

    context "with language filter" do
      let!(:english_doc) do
        oer = create(:oer, institution: institution, staff: staff, title: "English Doc")
        create(:metadatum, oer: oer, key: 'language', value: 'english')
        oer
      end

      let!(:spanish_doc) do
        oer = create(:oer, institution: institution, staff: staff, title: "Spanish Doc")
        create(:metadatum, oer: oer, key: 'language', value: 'spanish')
        oer
      end

      it "filters by language" do
        result = described_class.call('language' => ['spanish'])

        expect(result).to include(spanish_doc)
        expect(result).not_to include(english_doc)
      end
    end

    context "with publishing_date filter" do
      let!(:doc_2024) do
        oer = create(:oer, institution: institution, staff: staff, title: "2024 Doc")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-06-15')
        oer
      end

      let!(:doc_2023) do
        oer = create(:oer, institution: institution, staff: staff, title: "2023 Doc")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-03-20')
        oer
      end

      it "filters by publishing year" do
        result = described_class.call('publishing_date' => ['2024'])

        expect(result).to include(doc_2024)
        expect(result).not_to include(doc_2023)
      end

      it "filters by multiple years" do
        result = described_class.call('publishing_date' => ['2023', '2024'])

        expect(result).to include(doc_2024, doc_2023)
      end

      it "extracts year from full date format" do
        result = described_class.call('publishing_date' => ['2024'])

        expect(result).to include(doc_2024)
      end
    end

    context "with multiple filters combined" do
      let!(:cs_book_2024) do
        oer = create(:oer, institution: institution, staff: staff, title: "CS Book 2024")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-01-01')
        oer
      end

      let!(:cs_article_2023) do
        oer = create(:oer, institution: institution, staff: staff, title: "CS Article 2023")
        create(:metadatum, oer: oer, key: 'document_type', value: 'article')
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-01-01')
        oer
      end

      let!(:econ_book_2024) do
        oer = create(:oer, institution: institution, staff: staff, title: "Econ Book 2024")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        create(:metadatum, oer: oer, key: 'department', value: 'economics')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-01-01')
        oer
      end

      it "applies all filters together" do
        result = described_class.call(
          'document_type' => ['book'],
          'department' => ['computer science'],
          'publishing_date' => ['2024']
        )

        expect(result).to include(cs_book_2024)
        expect(result).not_to include(cs_article_2023, econ_book_2024)
      end

      it "combines search with metadata filters" do
        result = described_class.call(
          search: 'CS',
          'document_type' => ['book']
        )

        expect(result).to include(cs_book_2024)
        expect(result).not_to include(cs_article_2023, econ_book_2024)
      end
    end

    context "with empty filter arrays" do
      let!(:doc) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        oer
      end

      it "ignores empty filter values" do
        result = described_class.call('document_type' => [])

        expect(result).to include(doc)
      end
    end

    context "edge cases" do
      let!(:doc_with_metadata) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc With Metadata")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        oer
      end

      let!(:doc_without_metadata) do
        create(:oer, institution: institution, staff: staff, title: "Doc Without Metadata")
      end

      it "only returns documents matching the filter criteria" do
        result = described_class.call('document_type' => ['book'])

        expect(result).to include(doc_with_metadata)
        expect(result).not_to include(doc_without_metadata)
      end

      it "returns distinct results when multiple joins occur" do
        oer = create(:oer, institution: institution, staff: staff, title: "Multi Meta")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')

        result = described_class.call(
          'document_type' => ['book'],
          'department' => ['computer science']
        )

        expect(result.to_a.count(oer)).to eq(1)
      end
    end
  end

  describe ".new" do
    it "accepts params and stores them" do
      params = { search: 'test' }
      filter = described_class.new(params)

      expect(filter.call).to be_a(ActiveRecord::Relation)
    end
  end
end
