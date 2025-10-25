# == Schema Information
#
# Table name: metadata
#
#  id         :integer          not null, primary key
#  key        :string           not null
#  value      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  oer_id     :integer          not null
#
# Indexes
#
#  index_metadata_on_oer_id          (oer_id)
#  index_metadata_on_oer_id_and_key  (oer_id,key) UNIQUE
#
# Foreign Keys
#
#  oer_id  (oer_id => oers.id)
#
FactoryBot.define do
  factory :metadatum do
    association :oer
    key { "author" }
    value { "John Doe" }
  end
end
