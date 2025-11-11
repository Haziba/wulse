require 'rails_helper'

RSpec.describe TracksStorage, type: :model do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution) }
  let(:small_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/small.pdf'), 'application/pdf') }
  let(:large_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/large.pdf'), 'application/pdf') }

  before do
    institution.update!(storage_used: 0)
  end

  describe 'creating a document with a file' do
    it 'updates the document file_size' do
      document = create(:document, institution: institution, staff: staff)
      document.file.attach(small_file)
      document.save!

      expect(document.reload.file_size).to eq(small_file.size)
    end

    it "updates the institution's storage_used" do
      expect {
        document = create(:document, institution: institution, staff: staff)
        document.file.attach(small_file)
        document.save!
      }.to change { institution.reload.storage_used }.by(small_file.size)
    end

    it 'handles documents without files' do
      document = create(:document, institution: institution, staff: staff)

      expect(document.file_size).to eq(0)
      expect(institution.reload.storage_used).to eq(0)
    end
  end

  describe 'updating a document file' do
    let!(:document) do
      document = create(:document, institution: institution, staff: staff)
      document.file.attach(small_file)
      document.save!
      document.reload
    end

    it 'updates file_size when replacing with a larger file' do
      old_size = document.file_size
      document.file.attach(large_file)
      document.save!

      expect(document.reload.file_size).to eq(large_file.size)
      expect(document.file_size).to be > old_size
    end

    it 'adjusts institution storage_used by the delta when replacing' do
      initial_storage = institution.reload.storage_used
      size_delta = large_file.size - small_file.size

      document.file.attach(large_file)
      document.save!

      expect(institution.reload.storage_used).to eq(initial_storage + size_delta)
    end

    it 'handles replacing with a smaller file' do
      document.file.attach(large_file)
      document.save!
      initial_storage = institution.reload.storage_used

      size_delta = small_file.size - large_file.size
      document.file.attach(small_file)
      document.save!

      expect(document.reload.file_size).to eq(small_file.size)
      expect(institution.reload.storage_used).to eq(initial_storage + size_delta)
    end
  end

  describe 'deleting a document' do
    let!(:document) do
      document = create(:document, institution: institution, staff: staff)
      document.file.attach(small_file)
      document.save!
      document.reload
    end

    it "decrements the institution's storage_used" do
      initial_storage = institution.reload.storage_used
      file_size = document.file_size

      expect {
        document.destroy!
      }.to change { institution.reload.storage_used }.by(-file_size)
    end

    it 'handles deleting documents without files' do
      document_without_doc = create(:document, institution: institution, staff: staff)
      initial_storage = institution.reload.storage_used

      expect {
        document_without_doc.destroy!
      }.not_to change { institution.reload.storage_used }
    end
  end

  describe 'multiple operations' do
    it 'correctly tracks storage through multiple creates and deletes' do
      expect(institution.reload.storage_used).to eq(0)

      document1 = create(:document, institution: institution, staff: staff)
      document1.file.attach(small_file)
      document1.save!

      expect(institution.reload.storage_used).to eq(small_file.size)

      document2 = create(:document, institution: institution, staff: staff)
      document2.file.attach(large_file)
      document2.save!

      expect(institution.reload.storage_used).to eq(small_file.size + large_file.size)

      document1.destroy!

      expect(institution.reload.storage_used).to eq(large_file.size)

      document2.destroy!

      expect(institution.reload.storage_used).to eq(0)
    end
  end
end
