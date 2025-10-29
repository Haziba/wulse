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
        document = create(:document, institution: institution, staff: staff, title: "Book One")
        create(:metadatum, document: document, key: 'document_type',  value: 'book')
        create(:metadatum, document: document, key: 'department',     value: 'computer science')
        create(:metadatum, document: document, key: 'language',       value: 'english')
        create(:metadatum, document: document, key: 'publishing_date', value: '2024-01-15')
        document
      end

      let!(:document2) do
        document = create(:document, institution: institution, staff: staff, title: "Book Two")
        create(:metadatum, document: document, key: 'document_type',  value: 'book')
        create(:metadatum, document: document, key: 'department',     value: 'economics')
        create(:metadatum, document: document, key: 'language',       value: 'english')
        create(:metadatum, document: document, key: 'publishing_date', value: '2024-06-20')
        document
      end

      let!(:document3) do
        document = create(:document, institution: institution, staff: staff, title: "Article One")
        create(:metadatum, document: document, key: 'document_type',  value: 'article')
        create(:metadatum, document: document, key: 'department',     value: 'computer science')
        create(:metadatum, document: document, key: 'language',       value: 'spanish')
        create(:metadatum, document: document, key: 'publishing_date', value: '2023-03-10')
        document
      end

      it "returns all filter categories" do
        result = described_class.new(Document.all).call
        expect(result.map(&:first)).to match_array(['document_type', 'department', 'language', :publishing_date])
      end

      it "returns the filtered count for languages with filtered=total when scope is all" do
        result = result_hash_for(Document.all)
        expect(result['language']).to eq([
          ['english', 2],
          ['spanish', 1]
        ])
      end

      it "extracts publishing years and returns the filtered count for publishing_date with filtered=total when scope is all" do
        result = result_hash_for(Document.all)
        expect(result[:publishing_date]).to eq([
          ['2024', 2],
          ['2023', 1]
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
        document = create(:document, institution: institution, staff: staff, title: "2024 CS Book")
        create(:metadatum, document: document, key: 'department',      value: 'computer science')
        create(:metadatum, document: document, key: 'publishing_date', value: '2024-01-01')
        document
      end

      let!(:document2) do
        document = create(:document, institution: institution, staff: staff, title: "2023 CS Article")
        create(:metadatum, document: document, key: 'department',      value: 'computer science')
        create(:metadatum, document: document, key: 'publishing_date', value: '2023-01-01')
        document
      end

      let!(:document3) do
        document = create(:document, institution: institution, staff: staff, title: "2023 Economics")
        create(:metadatum, document: document, key: 'department',      value: 'economics')
        create(:metadatum, document: document, key: 'publishing_date', value: '2023-06-01')
        document
      end

      it "reports filtered counts from the scope and total counts from the unfiltered set (departments)" do
        scope  = Document.where(id: document1.id)
        result = result_hash_for(scope)

        expect(result['department']).to eq([
          ['computer science', 1],
          ['economics',        0]
        ])
      end

      it "reports filtered vs total for publishing_date years" do
        scope  = Document.where(id: document2.id) # one of the 2023 records
        result = result_hash_for(scope)

        expect(result[:publishing_date]).to eq([
          ['2023', 1],
          ['2024', 0]
        ])
      end
    end

    context "with multiple scopes (filtering one year only)" do
      let!(:doc2024) do
        document = create(:document, institution: institution, staff: staff, title: "Doc 2024")
        create(:metadatum, document: document, key: 'publishing_date', value: '2024-01-01')
        document
      end

      let!(:doc2023) do
        document = create(:document, institution: institution, staff: staff, title: "Doc 2023")
        create(:metadatum, document: document, key: 'publishing_date', value: '2023-01-01')
        document
      end

      it "shows only the scoped year with count>0, and other years with count=0" do
        scope  = Document.where(id: doc2024.id)
        result = result_hash_for(scope)

        expect(result[:publishing_date]).to eq([
          ['2024', 1],
          ['2023', 0]
        ])
      end
    end

    context "with various date formats" do
      let!(:document1) do
        document = create(:document, institution: institution, staff: staff, title: "Doc 1")
        create(:metadatum, document: document, key: 'publishing_date', value: '2024-12-25')
        document
      end

      let!(:document2) do
        document = create(:document, institution: institution, staff: staff, title: "Doc 2")
        create(:metadatum, document: document, key: 'publishing_date', value: '2023-06-15')
        document
      end

      let!(:document3) do
        document = create(:document, institution: institution, staff: staff, title: "Doc 3")
        create(:metadatum, document: document, key: 'publishing_date', value: '2023-01-01')
        document
      end

      it "handles ISO YYYY-MM-DD and aggregates by year with the filtered count" do
        result = result_hash_for(Document.all)
        expect(result[:publishing_date]).to eq([
          ['2023', 2],
          ['2024', 1]
        ])
      end
    end

    context "with blank or nil publishing dates" do
      let!(:document1) do
        document = create(:document, institution: institution, staff: staff, title: "Doc with date")
        create(:metadatum, document: document, key: 'publishing_date', value: '2024-01-01')
        document
      end

      let!(:document2) do
        document = create(:document, institution: institution, staff: staff, title: "Doc without date")
        create(:metadatum, document: document, key: 'publishing_date', value: '')
        document
      end

      let!(:document3) do
        document = create(:document, institution: institution, staff: staff, title: "Doc with nil date")
        create(:metadatum, document: document, key: 'publishing_date', value: nil)
        document
      end

      it "excludes blank and nil dates from both filtered and total counts" do
        result = result_hash_for(Document.all)
        expect(result[:publishing_date]).to eq([
          ['2024', 1]
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
      expect(result['document_type']).to eq([['book', 1]])
    end
  end
end
