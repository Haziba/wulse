class ChangeForeignKeyOnMetadataToDocuments < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :metadata, :documents
    add_foreign_key :metadata, :documents, on_delete: :cascade
  end
end
