class ChangeStorageTotalToBigintOnInstitutions < ActiveRecord::Migration[8.0]
  def change
    change_column :institutions, :storage_total, :bigint
  end
end
