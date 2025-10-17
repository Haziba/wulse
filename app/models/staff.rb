class Staff < ApplicationRecord
  has_secure_password

  has_many :oers
end
