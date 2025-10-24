FactoryBot.define do
  factory :metadatum do
    association :oer
    key { "author" }
    value { "John Doe" }
  end
end
