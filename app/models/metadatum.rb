class Metadatum < ApplicationRecord
  belongs_to :oer

  validates :key, presence: true, uniqueness: { scope: :oer_id }
end
