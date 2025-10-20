FactoryBot.define do
  factory :staff do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { "password" }
    institution
  end
end
