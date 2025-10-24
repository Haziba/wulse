class AddStorageUsedToInstitutions < ActiveRecord::Migration[8.0]
  def change
    add_column :institutions, :storage_used, :integer, limit: 8, default: 0, null: false
  end
end
