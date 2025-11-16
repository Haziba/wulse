# == Schema Information
#
# Table name: metadata
#
#  id          :uuid             not null, primary key
#  key         :string           not null
#  value       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  document_id :uuid             not null
#
# Indexes
#
#  index_metadata_on_document_id          (document_id)
#  index_metadata_on_document_id_and_key  (document_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (document_id => documents.id) ON DELETE => cascade
#
require 'rails_helper'

RSpec.describe Metadatum, type: :model do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:document) { create(:document, institution: institution, staff: staff) }

  describe 'associations' do
    it 'belongs to a document' do
      metadatum = create(:metadatum, document: document)
      expect(metadatum.document).to eq(document)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      metadatum = build(:metadatum, document: document, key: 'author', value: 'John Doe')
      expect(metadatum).to be_valid
    end

    it 'requires a key' do
      metadatum = build(:metadatum, document: document, key: nil)
      expect(metadatum).not_to be_valid
      expect(metadatum.errors[:key]).to include("can't be blank")
    end

    it 'allows blank value' do
      metadatum = build(:metadatum, document: document, key: 'description', value: '')
      expect(metadatum).to be_valid
    end

    it 'allows nil value' do
      metadatum = build(:metadatum, document: document, key: 'description', value: nil)
      expect(metadatum).to be_valid
    end
  end

  describe 'uniqueness validation' do
    let!(:existing_metadatum) { create(:metadatum, document: document, key: 'author', value: 'Jane Smith') }

    it 'does not allow duplicate keys for the same Document' do
      duplicate_metadatum = build(:metadatum, document: document, key: 'author', value: 'Different Author')
      expect(duplicate_metadatum).not_to be_valid
      expect(duplicate_metadatum.errors[:key]).to include('has already been taken')
    end

    it 'allows the same key for different Documents' do
      other_document = create(:document, institution: institution, staff: staff)
      metadatum = build(:metadatum, document: other_document, key: 'author', value: 'Different Author')
      expect(metadatum).to be_valid
    end

    it 'allows different keys for the same Document' do
      metadatum = build(:metadatum, document: document, key: 'publisher', value: 'Some Publisher')
      expect(metadatum).to be_valid
    end
  end

  describe 'Document association' do
    it 'is deleted when the Document is deleted' do
      metadatum = create(:metadatum, document: document, key: 'author', value: 'John Doe')

      expect {
        document.destroy
      }.to change(Metadatum, :count).by(-2)  # -2 because factory creates title metadata
    end

    it 'deletes multiple metadata when Document is deleted' do
      create(:metadatum, document: document, key: 'author', value: 'John Doe')
      create(:metadatum, document: document, key: 'publisher', value: 'ABC Publishing')
      create(:metadatum, document: document, key: 'year', value: '2024')

      expect {
        document.destroy
      }.to change(Metadatum, :count).by(-4)  # -4 because factory creates title metadata + 3 created above
    end
  end

  describe 'multiple metadata per Document' do
    it 'allows a Document to have multiple metadata with different keys' do
      create(:metadatum, document: document, key: 'author', value: 'John Doe')
      create(:metadatum, document: document, key: 'publisher', value: 'ABC Publishing')
      create(:metadatum, document: document, key: 'year', value: '2024')

      expect(document.metadata.count).to be >= 3
    end

    it 'can retrieve metadata by key' do
      create(:metadatum, document: document, key: 'author', value: 'John Doe')
      create(:metadatum, document: document, key: 'publisher', value: 'ABC Publishing')

      author_metadata = document.metadata.find_by(key: 'author')
      expect(author_metadata.value).to eq('John Doe')
    end
  end
end
