# == Schema Information
#
# Table name: documents
#
#  id             :integer          not null, primary key
#  document_size  :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :integer          not null
#  staff_id       :integer          not null
#
# Indexes
#
#  index_documents_on_document_size   (document_size)
#  index_documents_on_institution_id  (institution_id)
#  index_documents_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  institution_id  (institution_id => institutions.id)
#  staff_id        (staff_id => staffs.id)
#
require 'rails_helper'

RSpec.describe Document, type: :model do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  describe 'associations' do
    it 'belongs to staff' do
      document = create(:document, institution: institution, staff: staff)
      expect(document.staff).to eq(staff)
    end

    it 'belongs to institution' do
      document = create(:document, institution: institution, staff: staff)
      expect(document.institution).to eq(institution)
    end

    it 'has many metadata' do
      document = create(:document, institution: institution, staff: staff)
      create(:metadatum, document: document, key: 'author', value: 'John Doe')
      create(:metadatum, document: document, key: 'year', value: '2024')

      expect(document.metadata.count).to be >= 2
    end
  end

  describe 'title' do
    it 'returns the title metadata value' do
      document = create(:document, institution: institution, staff: staff, title: 'Test PDF Document')
      expect(document.title).to eq('Test PDF Document')
    end
  end

  describe 'authors' do
    it 'returns the authors metadata value' do
      document = create(:document, institution: institution, staff: staff)
      create(:metadatum, document: document, key: 'authors', value: 'John Doe, Jane Doe')
      expect(document.authors).to eq('John Doe, Jane Doe')
    end

    it 'returns the author metadata values when authors metadata is not present' do
      document = create(:document, institution: institution, staff: staff)
      create(:metadatum, document: document, key: 'author', value: 'John Doe')
      expect(document.authors).to eq('John Doe')
    end
  end
end
