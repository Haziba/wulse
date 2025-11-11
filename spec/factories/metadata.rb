# == Schema Information
#
# Table name: metadata
#
#  id          :integer          not null, primary key
#  key         :string           not null
#  value       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  document_id :integer          not null
#
# Indexes
#
#  index_metadata_on_document_id          (document_id)
#  index_metadata_on_document_id_and_key  (document_id,key) UNIQUE
#
# Foreign Keys
#
#  document_id  (document_id => documents.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :metadatum do
    association :document
    key { "author" }
    value { "John Doe" }
  end
end
