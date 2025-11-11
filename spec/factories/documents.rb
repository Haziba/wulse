# == Schema Information
#
# Table name: documents
#
#  id             :integer          not null, primary key
#  file_size      :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :integer          not null
#  staff_id       :integer          not null
#
# Indexes
#
#  index_documents_on_file_size       (file_size)
#  index_documents_on_institution_id  (institution_id)
#  index_documents_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  institution_id  (institution_id => institutions.id)
#  staff_id        (staff_id => staffs.id)
#
FactoryBot.define do
  factory :document do
    association :institution
    association :staff

    transient do
      title { nil }
    end

    after(:build) do |document, evaluator|
      document.metadata.build(key: 'title', value: evaluator.title || Faker::Book.title)
    end
  end
end
