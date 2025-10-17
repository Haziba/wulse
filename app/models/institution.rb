class Institution < ApplicationRecord
  has_many :staffs
  has_many :oers

  has_one_attached :logo

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'subdomain']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staffs', 'oers']
  end
end
