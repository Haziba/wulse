# == Schema Information
#
# Table name: oers
#
#  id             :integer          not null, primary key
#  file_size      :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :integer          not null
#  staff_id       :integer          not null
#
# Indexes
#
#  index_oers_on_file_size       (file_size)
#  index_oers_on_institution_id  (institution_id)
#  index_oers_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  institution_id  (institution_id => institutions.id)
#  staff_id        (staff_id => staffs.id)
#
require 'rails_helper'

RSpec.describe Oer, type: :model do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  describe 'associations' do
    it 'belongs to staff' do
      oer = create(:oer, institution: institution, staff: staff)
      expect(oer.staff).to eq(staff)
    end

    it 'belongs to institution' do
      oer = create(:oer, institution: institution, staff: staff)
      expect(oer.institution).to eq(institution)
    end

    it 'has many metadata' do
      oer = create(:oer, institution: institution, staff: staff)
      create(:metadatum, oer: oer, key: 'author', value: 'John Doe')
      create(:metadatum, oer: oer, key: 'year', value: '2024')

      expect(oer.metadata.count).to be >= 2
    end
  end

  describe 'title' do
    it 'returns the title metadata value' do
      oer = create(:oer, institution: institution, staff: staff, title: 'Test PDF Document')
      expect(oer.title).to eq('Test PDF Document')
    end
  end

  describe 'authors' do
    it 'returns the authors metadata value' do
      oer = create(:oer, institution: institution, staff: staff)
      create(:metadatum, oer: oer, key: 'authors', value: 'John Doe, Jane Doe')
      expect(oer.authors).to eq('John Doe, Jane Doe')
    end

    it 'returns the author metadata values when authors metadata is not present' do
      oer = create(:oer, institution: institution, staff: staff)
      create(:metadatum, oer: oer, key: 'author', value: 'John Doe')
      expect(oer.authors).to eq('John Doe')
    end
  end
end
