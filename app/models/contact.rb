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
class Contact < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    %w[contact_name created_at document_volume email institution_name institution_type requirements updated_at]
  end
end
