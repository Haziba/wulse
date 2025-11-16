FactoryBot.define do
  factory :password_reset do
    association :staff
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 24.hours.from_now }
  end
end
