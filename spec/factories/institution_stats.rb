FactoryBot.define do
  factory :institution_stat do
    association :institution
    date { Date.current.to_date }
    total_documents { 0 }
    active_staff { 0 }
    storage_used { 0 }
  end
end
