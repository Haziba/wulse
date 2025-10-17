class Institution < ApplicationRecord
  has_many :staffs
  has_many :oers
end
