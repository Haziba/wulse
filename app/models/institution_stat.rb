# == Schema Information
#
# Table name: institution_stats
#
#  id              :uuid             not null, primary key
#  active_staff    :integer
#  date            :date             not null
#  storage_used    :integer
#  total_documents :integer
#  institution_id  :uuid             not null
#
# Indexes
#
#  index_institution_stats_on_institution_id  (institution_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#
class InstitutionStat < ApplicationRecord
  belongs_to :institution

  validates :date, presence: true, uniqueness: { scope: :institution_id }
  validates :institution, presence: true

  def self.record_daily(institution)
    institution.institution_stats.create(
      date: Date.current.to_date,
      total_documents: institution.documents.count,
      active_staff: institution.staffs.where(status: 'active').count,
      storage_used: institution.storage_used
    )
  end
end
