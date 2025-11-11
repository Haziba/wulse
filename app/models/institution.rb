# == Schema Information
#
# Table name: institutions
#
#  id              :integer          not null, primary key
#  branding_colour :string
#  name            :string
#  storage_total   :integer          default(0)
#  storage_used    :integer          default(0), not null
#  subdomain       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Institution < ApplicationRecord
  has_many :staffs
  has_many :documents
  has_many :institution_stats

  has_one_attached :logo

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'subdomain']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staffs', 'documents']
  end

  # Recalculate storage_used from scratch (useful for backfilling or fixing drift)
  def recalculate_storage!
    total = documents.sum(:file_size)
    update!(storage_used: total)
    total
  end

  # Human-readable storage display
  def storage_used_human
    ActiveSupport::NumberHelper.number_to_human_size(storage_used)
  end
end
