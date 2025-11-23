# spec/services/library/filter_counts_spec.rb
require 'rails_helper'

RSpec.describe Library::FilterCounts do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  # Small helper: convert the service's array-of-pairs into a hash for easier expectations
  def result_hash_for(scope)
    described_class.new(scope).call.to_h
  end

  describe "#call" do
    context "with no documents" do
      it "returns empty arrays for all filters" do
        result = result_hash_for(Document.none)

        expect(result).to eq({
          'document_type' => [],
          'department'    => [],
          'language'      => [],
          publishing_date: []
        })
      end
    end

    context "with documents" do
      let!(:document1) do
        document = create(:document, institution: institution, staff: staff, title: "Book One", publishing_date: '2024-01-15')
        create(:metadatum, document: document, key: 'document_type',  value: 'book')
        create(:metadatum, document: document, key: 'department',     value: 'computer science')
        create(:metadatum, document: document, key: 'language',       value: 'english')
        document
      end

      let!(:document2) do
        document = create(:document, institution: institution, staff: staff, title: "Book Two", publishing_date: '2024-06-20')
        create(:metadatum, document: document, key: 'document_type',  value: 'book')
        create(:metadatum, document: document, key: 'department',     value: 'economics')
        create(:metadatum, document: document, key: 'language',       value: 'english')
        document
      end

      let!(:document3) do
        document = create(:document, institution: institution, staff: staff, title: "Article One", publishing_date: '2023-03-10')
        create(:metadatum, document: document, key: 'document_type',  value: 'article')
        create(:metadatum, document: document, key: 'department',     value: 'computer science')
        create(:metadatum, document: document, key: 'language',       value: 'spanish')
        document
      end

      it "returns all filter categories" do
        result = described_class.new(Document.all).call
        expect(result.map(&:first)).to match_array([ 'document_type', 'department', 'language', :publishing_date ])
      end

      it "returns the filtered count for languages with filtered=total when scope is all" do
        result = result_hash_for(Document.all)
        expect(result['language']).to eq([
          [ 'english', 2 ],
          [ 'spanish', 1 ]
        ])
      end

      it "extracts publishing years and returns the filtered count for publishing_date with filtered=total when scope is all" do
        result = result_hash_for(Document.all)
        expect(result[:publishing_date]).to eq([
          [ '2024', 2 ],
          [ '2023', 1 ]
        ])
      end

      it "sorts each category by filtered count descending" do
        result = result_hash_for(Document.all)
        result.each do |_, counts|
          sorted = counts.sort_by { |(_, count)| -count }
          expect(counts).to eq(sorted)
        end
      end
    end

    context "with a restrictive scope" do
      let!(:document1) do
        document = create(:document, institution: institution, staff: staff, title: "2024 CS Book", publishing_date: '2024-01-01')
        create(:metadatum, document: document, key: 'department', value: 'computer science')
        document
      end

      let!(:document2) do
        document = create(:document, institution: institution, staff: staff, title: "2023 CS Article", publishing_date: '2023-01-01')
        create(:metadatum, document: document, key: 'department', value: 'computer science')
        document
      end

      let!(:document3) do
        document = create(:document, institution: institution, staff: staff, title: "2023 Economics", publishing_date: '2023-06-01')
        create(:metadatum, document: document, key: 'department', value: 'economics')
        document
      end

      it "reports filtered counts from the scope and total counts from the unfiltered set (departments)" do
        scope  = Document.where(id: document1.id)
        result = result_hash_for(scope)

        expect(result['department']).to eq([
          [ 'computer science', 1 ],
          [ 'economics',        0 ]
        ])
      end

      it "reports filtered vs total for publishing_date years" do
        scope  = Document.where(id: document2.id) # one of the 2023 records
        result = result_hash_for(scope)

        expect(result[:publishing_date]).to eq([
          [ '2023', 1 ],
          [ '2024', 0 ]
        ])
      end
    end

    context "with multiple scopes (filtering one year only)" do
      let!(:doc2024) do
        create(:document, institution: institution, staff: staff, title: "Doc 2024", publishing_date: '2024-01-01')
      end

      let!(:doc2023) do
        create(:document, institution: institution, staff: staff, title: "Doc 2023", publishing_date: '2023-01-01')
      end

      it "shows only the scoped year with count>0, and other years with count=0" do
        scope  = Document.where(id: doc2024.id)
        result = result_hash_for(scope)

        expect(result[:publishing_date]).to eq([
          [ '2024', 1 ],
          [ '2023', 0 ]
        ])
      end
    end

    context "with various date formats" do
      let!(:document1) do
        create(:document, institution: institution, staff: staff, title: "Doc 1", publishing_date: '2024-12-25')
      end

      let!(:document2) do
        create(:document, institution: institution, staff: staff, title: "Doc 2", publishing_date: '2023-06-15')
      end

      let!(:document3) do
        create(:document, institution: institution, staff: staff, title: "Doc 3", publishing_date: '2023-01-01')
      end

      it "handles ISO YYYY-MM-DD and aggregates by year with the filtered count" do
        result = result_hash_for(Document.all)
        expect(result[:publishing_date]).to eq([
          [ '2023', 2 ],
          [ '2024', 1 ]
        ])
      end
    end

    context "with blank or nil publishing dates" do
      let!(:document1) do
        create(:document, institution: institution, staff: staff, title: "Doc with date", publishing_date: '2024-01-01')
      end

      let!(:document2) do
        doc = create(:document, institution: institution, staff: staff, title: "Doc without date", publishing_date: '2020-01-01')
        doc.metadata.find_by(key: 'publishing_date').update!(value: '')
        doc
      end

      let!(:document3) do
        doc = create(:document, institution: institution, staff: staff, title: "Doc with nil date", publishing_date: '2020-01-01')
        doc.metadata.find_by(key: 'publishing_date').update!(value: nil)
        doc
      end

      it "excludes blank and nil dates from both filtered and total counts" do
        result = result_hash_for(Document.all)
        expect(result[:publishing_date]).to eq([
          [ '2024', 1 ]
        ])
      end
    end
  end

  describe ".for" do
    let!(:document) do
      document = create(:document, institution: institution, staff: staff)
      create(:metadatum, document: document, key: 'document_type', value: 'book')
      document
    end

    it "is a convenience method that returns the filtered count for document_type" do
      result = described_class.for(Document.all).to_h

      expect(result).to have_key('document_type')
      expect(result['document_type']).to eq([ [ 'book', 1 ] ])
    end
  end

  describe "(Unknown) counts" do
    context "when documents are missing metadata keys" do
      let!(:doc_with_dept) do
        document = create(:document, institution: institution, staff: staff, title: "Doc with department")
        create(:metadatum, document: document, key: 'department', value: 'computer science')
        create(:metadatum, document: document, key: 'language', value: 'english')
        document
      end

      let!(:doc_without_dept) do
        document = create(:document, institution: institution, staff: staff, title: "Doc without department")
        create(:metadatum, document: document, key: 'language', value: 'english')
        document
      end

      let!(:doc_without_lang) do
        document = create(:document, institution: institution, staff: staff, title: "Doc without language")
        create(:metadatum, document: document, key: 'department', value: 'economics')
        document
      end

      it "includes (Unknown) count for documents missing department metadata" do
        result = result_hash_for(Document.all)

        unknown_entry = result['department'].find { |k, _| k == '(Unknown)' }
        expect(unknown_entry).to eq([ '(Unknown)', 1 ])
      end

      it "includes (Unknown) count for documents missing language metadata" do
        result = result_hash_for(Document.all)

        unknown_entry = result['language'].find { |k, _| k == '(Unknown)' }
        expect(unknown_entry).to eq([ '(Unknown)', 1 ])
      end

      it "shows (Unknown) with zero count when scope excludes unknowns but they exist overall" do
        result = result_hash_for(Document.where(id: doc_with_dept.id))

        unknown_entry = result['department'].find { |k, _| k == '(Unknown)' }
        expect(unknown_entry).to eq([ '(Unknown)', 0 ])
      end
    end

    context "when multiple documents are missing metadata" do
      let!(:doc1) do
        create(:document, institution: institution, staff: staff, title: "Doc 1")
      end

      let!(:doc2) do
        create(:document, institution: institution, staff: staff, title: "Doc 2")
      end

      let!(:doc3) do
        document = create(:document, institution: institution, staff: staff, title: "Doc 3")
        create(:metadatum, document: document, key: 'document_type', value: 'book')
        document
      end

      it "counts all documents missing the metadata key" do
        result = result_hash_for(Document.all)

        unknown_entry = result['document_type'].find { |k, _| k == '(Unknown)' }
        expect(unknown_entry).to eq([ '(Unknown)', 2 ])
      end
    end

    context "when the only option is (Unknown)" do
      let!(:doc_without_any_metadata) do
        create(:document, institution: institution, staff: staff, title: "Doc without metadata")
      end

      it "hides the filter category entirely" do
        result = result_hash_for(Document.all)

        expect(result).not_to have_key('document_type')
        expect(result).not_to have_key('department')
        expect(result).not_to have_key('language')
      end
    end
  end

  describe "sorting by checked state" do
    let!(:document1) do
      document = create(:document, institution: institution, staff: staff, title: "English Book")
      create(:metadatum, document: document, key: 'language', value: 'english')
      document
    end

    let!(:document2) do
      document = create(:document, institution: institution, staff: staff, title: "Another English Book")
      create(:metadatum, document: document, key: 'language', value: 'english')
      document
    end

    let!(:document3) do
      document = create(:document, institution: institution, staff: staff, title: "Spanish Book")
      create(:metadatum, document: document, key: 'language', value: 'spanish')
      document
    end

    let!(:document4) do
      document = create(:document, institution: institution, staff: staff, title: "French Book")
      create(:metadatum, document: document, key: 'language', value: 'french')
      document
    end

    it "places unchecked items at the bottom" do
      result = described_class.new(Document.all, selected_filters: { 'language' => [ 'spanish', 'french' ] }).call.to_h
      languages = result['language'].map(&:first)

      expect(languages.last).to eq('english')
      expect(languages[0..1]).to match_array([ 'spanish', 'french' ])
    end

    it "maintains count-based ordering within checked items" do
      result = described_class.new(Document.all, selected_filters: { 'language' => [ 'spanish', 'english' ] }).call.to_h
      languages = result['language'].map(&:first)

      expect(languages.first).to eq('english')
      expect(languages.last).to eq('french')
    end

    it "maintains count-based ordering within unchecked items" do
      result = described_class.new(Document.all, selected_filters: { 'language' => [ 'french' ] }).call.to_h
      languages = result['language'].map(&:first)

      expect(languages.first).to eq('french')
      expect(languages.last(2)).to match_array([ 'english', 'spanish' ])
    end

    it "keeps all items in count order when no filters are selected" do
      result = described_class.new(Document.all, selected_filters: {}).call.to_h
      languages = result['language'].map(&:first)

      expect(languages.first).to eq('english')
      expect(languages.last(2)).to match_array([ 'spanish', 'french' ])
    end
  end
end
