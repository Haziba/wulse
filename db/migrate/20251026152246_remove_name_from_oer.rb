class RemoveNameFromDocument < ActiveRecord::Migration[8.0]
  def change
    remove_column :documents, :name, :string
  end
end
