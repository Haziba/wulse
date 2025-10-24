require 'rails_helper'

RSpec.describe Metadatum, type: :model do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:oer) { create(:oer, institution: institution, staff: staff) }

  describe 'associations' do
    it 'belongs to an oer' do
      metadatum = create(:metadatum, oer: oer)
      expect(metadatum.oer).to eq(oer)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      metadatum = build(:metadatum, oer: oer, key: 'author', value: 'John Doe')
      expect(metadatum).to be_valid
    end

    it 'requires a key' do
      metadatum = build(:metadatum, oer: oer, key: nil)
      expect(metadatum).not_to be_valid
      expect(metadatum.errors[:key]).to include("can't be blank")
    end

    it 'allows blank value' do
      metadatum = build(:metadatum, oer: oer, key: 'description', value: '')
      expect(metadatum).to be_valid
    end

    it 'allows nil value' do
      metadatum = build(:metadatum, oer: oer, key: 'description', value: nil)
      expect(metadatum).to be_valid
    end
  end

  describe 'uniqueness validation' do
    let!(:existing_metadatum) { create(:metadatum, oer: oer, key: 'author', value: 'Jane Smith') }

    it 'does not allow duplicate keys for the same OER' do
      duplicate_metadatum = build(:metadatum, oer: oer, key: 'author', value: 'Different Author')
      expect(duplicate_metadatum).not_to be_valid
      expect(duplicate_metadatum.errors[:key]).to include('has already been taken')
    end

    it 'allows the same key for different OERs' do
      other_oer = create(:oer, institution: institution, staff: staff)
      metadatum = build(:metadatum, oer: other_oer, key: 'author', value: 'Different Author')
      expect(metadatum).to be_valid
    end

    it 'allows different keys for the same OER' do
      metadatum = build(:metadatum, oer: oer, key: 'publisher', value: 'Some Publisher')
      expect(metadatum).to be_valid
    end
  end

  describe 'OER association' do
    it 'is deleted when the OER is deleted' do
      metadatum = create(:metadatum, oer: oer, key: 'author', value: 'John Doe')

      expect {
        oer.destroy
      }.to change(Metadatum, :count).by(-1)
    end

    it 'deletes multiple metadata when OER is deleted' do
      create(:metadatum, oer: oer, key: 'author', value: 'John Doe')
      create(:metadatum, oer: oer, key: 'publisher', value: 'ABC Publishing')
      create(:metadatum, oer: oer, key: 'year', value: '2024')

      expect {
        oer.destroy
      }.to change(Metadatum, :count).by(-3)
    end
  end

  describe 'multiple metadata per OER' do
    it 'allows an OER to have multiple metadata with different keys' do
      create(:metadatum, oer: oer, key: 'author', value: 'John Doe')
      create(:metadatum, oer: oer, key: 'publisher', value: 'ABC Publishing')
      create(:metadatum, oer: oer, key: 'year', value: '2024')

      expect(oer.metadata.count).to eq(3)
    end

    it 'can retrieve metadata by key' do
      create(:metadatum, oer: oer, key: 'author', value: 'John Doe')
      create(:metadatum, oer: oer, key: 'publisher', value: 'ABC Publishing')

      author_metadata = oer.metadata.find_by(key: 'author')
      expect(author_metadata.value).to eq('John Doe')
    end
  end
end
