class RenameDocumentSizeToFileSize < ActiveRecord::Migration[7.0]
  def change
    rename_column :oers, :file_size, :file_size
  end
end