class Oer < ApplicationRecord
  acts_as_tenant :institution

  belongs_to :staff
  belongs_to :institution

  has_one_attached :document

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ['name']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staff', 'institution']
  end
end
