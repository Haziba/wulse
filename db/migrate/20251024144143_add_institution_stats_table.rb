class AddInstitutionStatsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :institution_stats, id: :uuid do |t|
      t.references :institution, null: false, foreign_key: true, type: :uuid
      t.date :date, null: false
      t.integer :total_documents
      t.integer :active_staff
      t.integer :storage_used
    end
  end
end
