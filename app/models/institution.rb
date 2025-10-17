class Institution < ApplicationRecord
  has_many :staffs
  has_many :oers

  has_one_attached :logo
end
