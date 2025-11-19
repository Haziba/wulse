# == Schema Information
#
# Table name: password_resets
#
#  id         :uuid             not null, primary key
#  expires_at :datetime         not null
#  token      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  staff_id   :uuid             not null
#
# Indexes
#
#  index_password_resets_on_staff_id  (staff_id)
#  index_password_resets_on_token     (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (staff_id => staffs.id)
#
FactoryBot.define do
  factory :password_reset do
    association :staff
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 24.hours.from_now }
  end
end
