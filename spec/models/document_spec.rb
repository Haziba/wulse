# == Schema Information
#
# Table name: documents
#
#  id             :uuid             not null, primary key
#  file_size      :bigint           default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :uuid             not null
#  staff_id       :uuid             not null
#
# Indexes
#
#  index_documents_on_file_size       (file_size)
#  index_documents_on_institution_id  (institution_id)
#  index_documents_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#  fk_rails_...  (staff_id => staffs.id)
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
      create(:metadatum, document: document, key: 'isbn', value: '123-456')
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

  describe 'author' do
    it 'returns the author metadata value' do
      document = create(:document, institution: institution, staff: staff, author: 'John Doe')
      expect(document.author).to eq('John Doe')
    end
  end
end
