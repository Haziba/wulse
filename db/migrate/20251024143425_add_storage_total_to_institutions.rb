class AddStorageTotalToInstitutions < ActiveRecord::Migration[8.0]
  def change
    add_column :institutions, :storage_total, :integer, default: 0
  end
end
