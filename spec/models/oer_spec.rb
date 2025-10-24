require 'rails_helper'

RSpec.describe Oer, type: :model do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }

  describe 'validations' do
    it 'requires a name' do
      oer = build(:oer, institution: institution, staff: staff, name: nil)
      expect(oer).not_to be_valid
      expect(oer.errors[:name]).to include("can't be blank")
    end
  end

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

      expect(oer.metadata.count).to eq(2)
    end
  end
end
