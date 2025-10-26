require 'rails_helper'

RSpec.describe Library::FilterCounts do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  describe "#call" do
    context "with no documents" do
      it "returns empty counts for all filters" do
        result = described_class.new(Oer.none).call

        expect(result).to eq({
          'document_type' => [],
          'department' => [],
          'language' => [],
          publishing_date: []
        })
      end
    end

    context "with documents" do
      let!(:oer1) do
        oer = create(:oer, institution: institution, staff: staff, title: "Book One")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')
        create(:metadatum, oer: oer, key: 'language', value: 'english')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-01-15')
        oer
      end

      let!(:oer2) do
        oer = create(:oer, institution: institution, staff: staff, title: "Book Two")
        create(:metadatum, oer: oer, key: 'document_type', value: 'book')
        create(:metadatum, oer: oer, key: 'department', value: 'economics')
        create(:metadatum, oer: oer, key: 'language', value: 'english')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-06-20')
        oer
      end

      let!(:oer3) do
        oer = create(:oer, institution: institution, staff: staff, title: "Article One")
        create(:metadatum, oer: oer, key: 'document_type', value: 'article')
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')
        create(:metadatum, oer: oer, key: 'language', value: 'spanish')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-03-10')
        oer
      end

      it "returns counts for all filter types" do
        result = described_class.new(Oer.all).call

        expect(result.keys).to match_array(['document_type', 'department', 'language', :publishing_date])
      end

      it "counts document types correctly" do
        result = described_class.new(Oer.all).call

        expect(result['document_type']).to eq([['book', 2], ['article', 1]])
      end

      it "counts departments correctly" do
        result = described_class.new(Oer.all).call

        expect(result['department']).to eq([['computer science', 2], ['economics', 1]])
      end

      it "counts languages correctly" do
        result = described_class.new(Oer.all).call

        expect(result['language']).to eq([['english', 2], ['spanish', 1]])
      end

      it "extracts years from publishing dates" do
        result = described_class.new(Oer.all).call

        expect(result[:publishing_date]).to eq([['2024', 2], ['2023', 1]])
      end

      it "sorts all filters by count descending" do
        result = described_class.new(Oer.all).call

        result.each do |_, counts|
          sorted = counts.sort_by { |_, count| -count }
          expect(counts).to eq(sorted)
        end
      end
    end

    context "with scoped documents" do
      let!(:oer1) do
        oer = create(:oer, institution: institution, staff: staff, title: "2024 CS Book")
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-01-01')
        oer
      end

      let!(:oer2) do
        oer = create(:oer, institution: institution, staff: staff, title: "2023 CS Article")
        create(:metadatum, oer: oer, key: 'department', value: 'computer science')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-01-01')
        oer
      end

      let!(:oer3) do
        oer = create(:oer, institution: institution, staff: staff, title: "2023 Economics")
        create(:metadatum, oer: oer, key: 'department', value: 'economics')
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-06-01')
        oer
      end

      it "respects the scope for publishing_date counts" do
        # Scope to only 2024 documents
        scope = Oer.where(id: oer1.id)
        result = described_class.new(scope).call

        # Simple filters count ALL records, not scoped
        expect(result['department']).to eq([['computer science', 2], ['economics', 1]])

        # But publishing_date respects the scope - only 2024
        expect(result[:publishing_date]).to eq([['2024', 1]])
      end
    end

    context "with multiple scopes" do
      let!(:doc2024) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc 2024")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-01-01')
        oer
      end

      let!(:doc2023) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc 2023")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-01-01')
        oer
      end

      it "uses the scope only for publishing_date filtering" do
        scope = Oer.where(id: doc2024.id)
        result = described_class.new(scope).call

        expect(result[:publishing_date]).to eq([['2024', 1]])
        expect(result[:publishing_date].map(&:first)).not_to include('2023')
      end
    end

    context "with various date formats" do
      let!(:oer1) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc 1")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-12-25')
        oer
      end

      let!(:oer2) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc 2")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-06-15')
        oer
      end

      let!(:oer3) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc 3")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2023-01-01')
        oer
      end

      it "handles ISO date format (YYYY-MM-DD)" do
        result = described_class.new(Oer.all).call

        expect(result[:publishing_date]).to eq([['2023', 2], ['2024', 1]])
      end
    end

    context "with blank or nil publishing dates" do
      let!(:oer1) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc with date")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '2024-01-01')
        oer
      end

      let!(:oer2) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc without date")
        create(:metadatum, oer: oer, key: 'publishing_date', value: '')
        oer
      end

      let!(:oer3) do
        oer = create(:oer, institution: institution, staff: staff, title: "Doc with nil date")
        create(:metadatum, oer: oer, key: 'publishing_date', value: nil)
        oer
      end

      it "excludes blank and nil dates from counts" do
        result = described_class.new(Oer.all).call

        expect(result[:publishing_date]).to eq([['2024', 1]])
      end
    end
  end

  describe ".for" do
    let!(:oer) do
      oer = create(:oer, institution: institution, staff: staff)
      create(:metadatum, oer: oer, key: 'document_type', value: 'book')
      oer
    end

    it "is a convenience method that creates an instance and calls #call" do
      result = described_class.for(Oer.all)

      expect(result).to be_a(Hash)
      expect(result['document_type']).to eq([['book', 1]])
    end
  end
end
