class AddDocumentSizeToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :file_size, :integer, limit: 8, default: 0, null: false
    add_index :documents, :file_size
  end
end
