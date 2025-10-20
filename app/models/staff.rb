class Staff < ApplicationRecord
  acts_as_tenant :institution

  has_secure_password

  has_many :oers
  belongs_to :institution

  enum :status, { active: 0, inactive: 1, away: 2 }

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'email']
  end

  def self.ransackable_associations(auth_object = nil)
    ['institution', 'oers']
  end
end
