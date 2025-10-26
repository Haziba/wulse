# == Schema Information
#
# Table name: oers
#
#  id             :integer          not null, primary key
#  document_size  :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :integer          not null
#  staff_id       :integer          not null
#
# Indexes
#
#  index_oers_on_document_size   (document_size)
#  index_oers_on_institution_id  (institution_id)
#  index_oers_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  institution_id  (institution_id => institutions.id)
#  staff_id        (staff_id => staffs.id)
#
FactoryBot.define do
  factory :oer do
    association :institution
    association :staff

    transient do
      title { nil }
    end

    after(:build) do |oer, evaluator|
      oer.metadata.build(key: 'title', value: evaluator.title || Faker::Book.title)
    end
  end
end
