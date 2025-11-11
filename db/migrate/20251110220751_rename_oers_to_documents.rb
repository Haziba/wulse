class RenameDocumentsToDocuments < ActiveRecord::Migration[8.0]
  def change
    rename_table :documents, :documents
    rename_column :metadata, :document_id, :document_id
  end
end
