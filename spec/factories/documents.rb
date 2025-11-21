# == Schema Information
#
# Table name: documents
#
#  id             :uuid             not null, primary key
#  file_size      :bigint           default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :uuid             not null
#  staff_id       :uuid             not null
#
# Indexes
#
#  index_documents_on_file_size       (file_size)
#  index_documents_on_institution_id  (institution_id)
#  index_documents_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#  fk_rails_...  (staff_id => staffs.id)
#
FactoryBot.define do
  factory :document do
    association :institution
    association :staff

    transient do
      title { nil }
      author { nil }
      publishing_date { nil }
    end

    after(:build) do |document, evaluator|
      document.metadata.build(key: 'title', value: evaluator.title || Faker::Book.title)
      document.metadata.build(key: 'author', value: evaluator.author || Faker::Name.name)
      document.metadata.build(key: 'publishing_date', value: evaluator.publishing_date || Faker::Date.between(from: '1900-01-01', to: '2025-12-31'))
    end
  end
end
