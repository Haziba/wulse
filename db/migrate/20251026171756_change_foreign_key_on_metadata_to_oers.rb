class ChangeForeignKeyOnMetadataToOers < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :metadata, :oers
    add_foreign_key :metadata, :oers, on_delete: :cascade
  end
end
