class Institution < ApplicationRecord
  has_many :staffs
  has_many :oers

  has_one_attached :logo

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'subdomain']
  end

  def self.ransackable_associations(auth_object = nil)
    ['staffs', 'oers']
  end

  # Recalculate storage_used from scratch (useful for backfilling or fixing drift)
  def recalculate_storage!
    total = oers.sum(:document_size)
    update!(storage_used: total)
    total
  end

  # Human-readable storage display
  def storage_used_human
    ActiveSupport::NumberHelper.number_to_human_size(storage_used)
  end
end
