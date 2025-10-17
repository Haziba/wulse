class Oer < ApplicationRecord
  acts_as_tenant :institution

  belongs_to :staff
  belongs_to :institution
end
