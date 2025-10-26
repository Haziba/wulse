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
  SUGGESTED_METADATA = %w[description publication_date document_type language department]

  acts_as_tenant :institution

  belongs_to :staff
  belongs_to :institution

  has_many :metadata, dependent: :destroy
  accepts_nested_attributes_for :metadata, allow_destroy: true, reject_if: :all_blank

  has_one_attached :document
  has_one_attached :preview_image

  validate :title_presence

  def self.ransackable_attributes(auth_object = nil)
    ['staff', 'institution']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staff', 'institution', 'metadata']
  end

  def title
    metadata.find_by(key: 'title')&.value
  end

  private

  def title_presence
    title_metadata = metadata.detect { |m| m.key == 'title' }
    if title_metadata.nil? || title_metadata.value.blank?
      errors.add(:base, "Title can't be blank")
    end
  end
end
