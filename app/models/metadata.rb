# == Schema Information
#
# Table name: metadata
#
#  id          :uuid             not null, primary key
#  key         :string           not null
#  value       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  document_id :uuid             not null
#
# Indexes
#
#  index_metadata_on_document_id          (document_id)
#  index_metadata_on_document_id_and_key  (document_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (document_id => documents.id) ON DELETE => cascade
#
class Metadata < ApplicationRecord
  belongs_to :document

  validates :key, presence: true, uniqueness: { scope: :document_id }
end
