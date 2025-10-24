class InstitutionStat < ApplicationRecord
  belongs_to :institution

  validates :date, presence: true, uniqueness: { scope: :institution_id }
  validates :institution, presence: true

  def self.record_daily(institution)
    institution.institution_stats.create(
      date: Date.current.to_date,
      total_documents: institution.oers.count,
      active_staff: institution.staffs.where(status: 'active').count,
      storage_used: institution.storage_used
    )
  end
end
