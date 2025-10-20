class Staff < ApplicationRecord
  acts_as_tenant :institution

  has_secure_password validations: false

  has_many :oers
  belongs_to :institution

  enum :status, { active: 0, inactive: 1, away: 2 }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :institution_id }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_digest_changed?

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'email']
  end

  def self.ransackable_associations(auth_object = nil)
    ['institution', 'oers']
  end
end
