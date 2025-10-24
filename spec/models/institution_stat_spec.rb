require 'rails_helper'

RSpec.describe InstitutionStat, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:institution) { create(:institution, storage_used: 50000) }
  let!(:staff1) { create(:staff, institution: institution, status: 'active') }
  let!(:staff2) { create(:staff, institution: institution, status: 'active') }
  let!(:staff3) { create(:staff, institution: institution, status: 'inactive') }

  describe '.record_daily' do
    before do
      # Create some OERs for the institution
      5.times { create(:oer, institution: institution, staff: staff1) }
      3.times { create(:oer, institution: institution, staff: staff2) }
    end

    it 'creates a new InstitutionStat record' do
      expect {
        InstitutionStat.record_daily(institution)
      }.to change(InstitutionStat, :count).by(1)
    end

    it 'records the correct date' do
      stat = InstitutionStat.record_daily(institution)

      expect(stat.date.to_date).to eq(Date.current)
    end

    it 'records the total number of documents' do
      stat = InstitutionStat.record_daily(institution)

      expect(stat.total_documents).to eq(8)
    end

    it 'records only active staff count' do
      stat = InstitutionStat.record_daily(institution)

      expect(stat.active_staff).to eq(2)
      expect(institution.staffs.count).to eq(3) # Verify we have 3 total
    end

    it 'records the current storage used' do
      stat = InstitutionStat.record_daily(institution)

      expect(stat.storage_used).to eq(50000)
    end

    it 'associates the stat with the correct institution' do
      stat = InstitutionStat.record_daily(institution)

      expect(stat.institution).to eq(institution)
    end

    context 'with no documents or staff' do
      let(:empty_institution) { create(:institution) }

      it 'records zeros for empty institution' do
        stat = InstitutionStat.record_daily(empty_institution)

        expect(stat.total_documents).to eq(0)
        expect(stat.active_staff).to eq(0)
        expect(stat.storage_used).to eq(0)
      end
    end

    context 'with changing data over multiple days' do
      it 'captures different snapshots on different days' do
        # Day 1: 8 documents, 2 active staff
        stat1 = nil
        travel_to Date.current.beginning_of_day do
          stat1 = InstitutionStat.record_daily(institution)
        end

        # Day 2: Add more documents and staff
        travel_to 1.day.from_now.beginning_of_day do
          3.times { create(:oer, institution: institution, staff: staff1) }
          create(:staff, institution: institution, status: 'active')

          stat2 = InstitutionStat.record_daily(institution)

          expect(stat2.total_documents).to eq(11)
          expect(stat2.active_staff).to eq(3)
          expect(stat2.date.to_date).to eq(Date.current)
        end

        # Original stat should be unchanged
        expect(stat1.reload.total_documents).to eq(8)
        expect(stat1.active_staff).to eq(2)
      end
    end

    context 'validation' do
      it 'prevents duplicate stats for same institution and date' do
        InstitutionStat.record_daily(institution)

        duplicate_stat = InstitutionStat.record_daily(institution)

        expect(duplicate_stat.persisted?).to be false
        expect(duplicate_stat.errors[:date]).to include('has already been taken')
      end

      it 'allows stats for different institutions on same date' do
        institution2 = create(:institution)

        stat1 = InstitutionStat.record_daily(institution)
        stat2 = InstitutionStat.record_daily(institution2)

        expect(stat1.date.to_date).to eq(stat2.date.to_date)
        expect(stat1.institution).not_to eq(stat2.institution)
      end

      it 'allows stats for same institution on different dates' do
        stat1 = nil
        travel_to Date.current.beginning_of_day do
          stat1 = InstitutionStat.record_daily(institution)
        end

        stat2 = nil
        travel_to 1.day.from_now.beginning_of_day do
          stat2 = InstitutionStat.record_daily(institution)
        end

        expect(stat1.institution).to eq(stat2.institution)
        expect(stat1.date.to_date).not_to eq(stat2.date.to_date)
      end
    end
  end
end
