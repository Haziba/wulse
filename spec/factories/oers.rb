FactoryBot.define do
  factory :oer do
    name { Faker::Book.title }
    association :institution
    association :staff
  end
end
