class Oer < ApplicationRecord
  include TracksStorage

  REQUIRED_METADATA = %w[isbn author title]

  acts_as_tenant :institution

  belongs_to :staff
  belongs_to :institution

  has_many :metadata, dependent: :destroy
  accepts_nested_attributes_for :metadata, allow_destroy: true, reject_if: :all_blank

  has_one_attached :document
  has_one_attached :preview_image

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ['name']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staff', 'institution']
  end
end
