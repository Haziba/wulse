# == Schema Information
#
# Table name: institution_stats
#
#  id              :uuid             not null, primary key
#  active_staff    :integer
#  date            :date             not null
#  storage_used    :integer
#  total_documents :integer
#  institution_id  :uuid             not null
#
# Indexes
#
#  index_institution_stats_on_institution_id  (institution_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#
FactoryBot.define do
  factory :institution_stat do
    association :institution
    date { Date.current.to_date }
    total_documents { 0 }
    active_staff { 0 }
    storage_used { 0 }
  end
end
