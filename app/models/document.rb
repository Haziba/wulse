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
class Document < ApplicationRecord
  include TracksStorage

  REQUIRED_METADATA = %w[publishing_date author title]
  SUGGESTED_METADATA = %w[document_type language department]

  acts_as_tenant :institution

  belongs_to :staff
  belongs_to :institution

  has_many :metadata, dependent: :destroy
  accepts_nested_attributes_for :metadata, allow_destroy: true, reject_if: :all_blank

  has_one_attached :file, dependent: :purge_later
  has_one_attached :preview_image, dependent: :purge_later

  validate :title_metadata_present
  validate :author_metadata_present
  validate :publishing_date_metadata_present

  def self.ransackable_attributes(auth_object = nil)
    %w[staff_id institution_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    [ 'staff', 'institution', 'metadata' ]
  end

  def title
    metadata.find_by(key: 'title')&.value
  end

  def author
    metadata.find_by(key: 'author')&.value
  end

  def publishing_date
    metadata.find_by(key: 'publishing_date')&.value
  end

  private

  def title_metadata_present
    metadata_present?('title')
  end

  def author_metadata_present
    metadata_present?('author')
  end

  def publishing_date_metadata_present
    metadata_present?('publishing_date')
  end

  def metadata_present?(key)
    metadata_meta = metadata.detect { |m| m.key == key && !m.marked_for_destruction? }
    if metadata_meta.nil? || metadata_meta.value.blank?
      errors.add(:base, "#{key} can't be blank")
    end
  end
end
