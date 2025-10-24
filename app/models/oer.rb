class Oer < ApplicationRecord
  acts_as_tenant :institution

  belongs_to :staff
  belongs_to :institution

  has_many :metadata, dependent: :destroy

  has_one_attached :document

  validates :name, presence: true

  # Update document_size and institution storage when document changes
  after_commit :sync_document_size, on: [:create, :update]
  before_destroy :prepare_storage_cleanup
  after_commit :cleanup_storage, on: :destroy

  def self.ransackable_attributes(auth_object = nil)
    ['name']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staff', 'institution']
  end

  # Helper to get current storage usage for this OER
  def current_document_size
    document.attached? ? document.byte_size : 0
  end

  private

  def sync_document_size
    new_size = current_document_size
    old_size = document_size || 0
    size_delta = new_size - old_size

    if size_delta != 0
      update_column(:document_size, new_size)
      institution.increment!(:storage_used, size_delta)
    end
  end

  def prepare_storage_cleanup
    @size_to_cleanup = document_size || 0
  end

  def cleanup_storage
    institution.decrement!(:storage_used, @size_to_cleanup) if @size_to_cleanup > 0
  end
end
