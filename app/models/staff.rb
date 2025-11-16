# == Schema Information
#
# Table name: staffs
#
#  id              :uuid             not null, primary key
#  email           :string
#  last_login      :datetime
#  name            :string
#  password_digest :string
#  status          :integer          default("active")
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  institution_id  :uuid             not null
#
# Indexes
#
#  index_staffs_on_institution_id  (institution_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#
class Staff < ApplicationRecord
  acts_as_tenant :institution

  has_secure_password validations: false

  has_one_attached :avatar
  has_many :documents
  belongs_to :institution

  enum :status, { active: 0, inactive: 1, away: 2 }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :institution_id }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_digest_changed?
  validates :password, confirmation: true, if: :password_digest_changed?

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'email']
  end

  def self.ransackable_associations(auth_object = nil)
    ['institution', 'documents']
  end
end
