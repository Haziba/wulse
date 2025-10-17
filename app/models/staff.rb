class Staff < ApplicationRecord
  acts_as_tenant :institution

  has_secure_password

  has_many :oers
  belongs_to :institution
end
