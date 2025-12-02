# == Schema Information
#
# Table name: contacts
#
#  id               :uuid             not null, primary key
#  contact_name     :string
#  document_volume  :string
#  email            :string
#  institution_name :string
#  institution_type :string
#  requirements     :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do
  factory :contact do
    institution_name { "MyString" }
    institution_type { "MyString" }
    contact_name { "MyString" }
    email { "MyString" }
    document_volume { "MyString" }
    requirements { "MyText" }
  end
end
