class AddDocumentSizeToOers < ActiveRecord::Migration[8.0]
  def change
    add_column :oers, :document_size, :integer, limit: 8, default: 0, null: false
    add_index :oers, :document_size
  end
end
