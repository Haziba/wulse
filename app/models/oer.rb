# == Schema Information
#
# Table name: oers
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
#  index_oers_on_document_size   (document_size)
#  index_oers_on_institution_id  (institution_id)
#  index_oers_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  institution_id  (institution_id => institutions.id)
#  staff_id        (staff_id => staffs.id)
#
class Oer < ApplicationRecord
  include TracksStorage

  REQUIRED_METADATA = %w[isbn author title]
  SUGGESTED_METADATA = %w[description publishing_date document_type language department]

  acts_as_tenant :institution

  belongs_to :staff
  belongs_to :institution

  has_many :metadata, dependent: :destroy
  accepts_nested_attributes_for :metadata, allow_destroy: true, reject_if: :all_blank

  has_one_attached :document, dependent: :purge_later
  has_one_attached :preview_image, dependent: :purge_later

  validate :title_metadata_present

  def self.ransackable_attributes(auth_object = nil)
    ['staff', 'institution']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staff', 'institution', 'metadata']
  end

  def title
    metadata.find_by(key: 'title')&.value
  end

  def authors
    metadata.find_by(key: 'authors')&.value || metadata.find_by(key: 'author')&.value
  end

  private

  def title_metadata_present
    title_meta = metadata.detect { |m| m.key == 'title' && !m.marked_for_destruction? }
    if title_meta.nil? || title_meta.value.blank?
      errors.add(:base, "Title can't be blank")
    end
  end
end
