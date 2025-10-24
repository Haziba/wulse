require 'rails_helper'

RSpec.describe TracksStorage, type: :model do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:small_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/small.pdf'), 'application/pdf') }
  let(:large_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/large.pdf'), 'application/pdf') }

  before do
    institution.update!(storage_used: 0)
  end

  describe 'creating an OER with a document' do
    it 'updates the OER document_size' do
      oer = create(:oer, institution: institution, staff: staff)
      oer.document.attach(small_file)
      oer.save!

      expect(oer.reload.document_size).to eq(small_file.size)
    end

    it "updates the institution's storage_used" do
      expect {
        oer = create(:oer, institution: institution, staff: staff)
        oer.document.attach(small_file)
        oer.save!
      }.to change { institution.reload.storage_used }.by(small_file.size)
    end

    it 'handles OERs without documents' do
      oer = create(:oer, institution: institution, staff: staff)

      expect(oer.document_size).to eq(0)
      expect(institution.reload.storage_used).to eq(0)
    end
  end

  describe 'updating an OER document' do
    let!(:oer) do
      oer = create(:oer, institution: institution, staff: staff)
      oer.document.attach(small_file)
      oer.save!
      oer.reload
    end

    it 'updates document_size when replacing with a larger file' do
      old_size = oer.document_size
      oer.document.attach(large_file)
      oer.save!

      expect(oer.reload.document_size).to eq(large_file.size)
      expect(oer.document_size).to be > old_size
    end

    it 'adjusts institution storage_used by the delta when replacing' do
      initial_storage = institution.reload.storage_used
      size_delta = large_file.size - small_file.size

      oer.document.attach(large_file)
      oer.save!

      expect(institution.reload.storage_used).to eq(initial_storage + size_delta)
    end

    it 'handles replacing with a smaller file' do
      oer.document.attach(large_file)
      oer.save!
      initial_storage = institution.reload.storage_used

      size_delta = small_file.size - large_file.size
      oer.document.attach(small_file)
      oer.save!

      expect(oer.reload.document_size).to eq(small_file.size)
      expect(institution.reload.storage_used).to eq(initial_storage + size_delta)
    end
  end

  describe 'deleting an OER' do
    let!(:oer) do
      oer = create(:oer, institution: institution, staff: staff)
      oer.document.attach(small_file)
      oer.save!
      oer.reload
    end

    it "decrements the institution's storage_used" do
      initial_storage = institution.reload.storage_used
      document_size = oer.document_size

      expect {
        oer.destroy!
      }.to change { institution.reload.storage_used }.by(-document_size)
    end

    it 'handles deleting OERs without documents' do
      oer_without_doc = create(:oer, institution: institution, staff: staff)
      initial_storage = institution.reload.storage_used

      expect {
        oer_without_doc.destroy!
      }.not_to change { institution.reload.storage_used }
    end
  end

  describe 'multiple operations' do
    it 'correctly tracks storage through multiple creates and deletes' do
      expect(institution.reload.storage_used).to eq(0)

      oer1 = create(:oer, institution: institution, staff: staff)
      oer1.document.attach(small_file)
      oer1.save!

      expect(institution.reload.storage_used).to eq(small_file.size)

      oer2 = create(:oer, institution: institution, staff: staff)
      oer2.document.attach(large_file)
      oer2.save!

      expect(institution.reload.storage_used).to eq(small_file.size + large_file.size)

      oer1.destroy!

      expect(institution.reload.storage_used).to eq(large_file.size)

      oer2.destroy!

      expect(institution.reload.storage_used).to eq(0)
    end
  end
end
